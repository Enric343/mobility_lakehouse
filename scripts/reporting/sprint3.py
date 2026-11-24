"""Read the published Gold snapshot and write its offline analytical report."""

from base64 import b64encode
from html import escape
from pathlib import Path
from tempfile import TemporaryDirectory

from lakehouse.catalog import read_sql
from lakehouse.validation import QualityError

from .charts import choropleths, gravity_coverage, hourly_profile


STYLE = """
  * { box-sizing: border-box }
  body { margin: 0; color: #183143; background: #edf2f4; font: 16px/1.5 system-ui, sans-serif }
  header { background: #143447; color: white; padding: 2rem max(1.25rem, calc((100% - 68rem)/2)) }
  h1 { margin: .3rem 0; font-size: clamp(1.9rem, 4vw, 3rem); line-height: 1.08 }
  header p { margin: .3rem 0; color: #d4e7ed }
  main { max-width: 70rem; margin: auto; padding: 0 1rem 2rem }
  section { background: white; padding: clamp(1rem, 3vw, 2rem); margin: 1rem 0; border-radius: 10px }
  h2, h3 { margin: .4rem 0 .7rem; line-height: 1.2 }
  figure { margin: 1.3rem 0 }
  img { display: block; max-width: 100%; height: auto; margin: auto }
  figcaption, .note { color: #4b6371; font-size: .94rem; margin-top: .45rem }
  .table { overflow-x: auto }
  table { border-collapse: collapse; width: 100%; font-variant-numeric: tabular-nums }
  th, td { text-align: left; padding: .5rem .7rem; border-bottom: 1px solid #e0eaef }
  th { background: #edf4f6 }
"""


def _table(headers, rows):
    heading = "".join(f'<th scope="col">{escape(str(label))}</th>' for label in headers)
    body = "".join("<tr>" + "".join(f"<td>{escape(str(value))}</td>" for value in row) + "</tr>" for row in rows)
    return f'<div class="table"><table><thead><tr>{heading}</tr></thead><tbody>{body}</tbody></table></div>'


def _figure(png, alt, caption):
    source = b64encode(png).decode("ascii")
    return f'<figure><img src="data:image/png;base64,{source}" alt="{escape(alt)}"><figcaption>{escape(caption)}</figcaption></figure>'


def _rank_table(rows):
    return _table(("Rank", "MITMA municipal zone", "Observed trips", "Estimated trips", "Ratio", "Pair coverage"), (
        (rank, f"{name} ({zone})", f"{actual:,.0f}", f"{estimated:,.0f}", f"{ratio:.1%}", f"{coverage:.1%}")
        for rank, zone, name, actual, estimated, ratio, coverage in rows
    ))


def publish_report(connection, output, start, end):
    connection.execute("SET VARIABLE gold_start = ?", [start])
    connection.execute("SET VARIABLE gold_end = ?", [end])
    completed_runs = connection.execute("""
        SELECT count(*), count(model_revision)
        FROM lake.main.gold_runs WHERE period_start = ? AND period_end = ?
    """, [start, end]).fetchone()
    if completed_runs != (1, 1):
        raise QualityError("Report requires one validated Gold run for the sample. Run scripts/build_gold.py first.")
    connection.execute(read_sql("reporting/sprint3.sql"))
    daily = connection.sql("""
        SELECT date, day_type, cluster_id, total_trips, peak_hour FROM report_days
        WHERE zone_level = 'municipios' ORDER BY date
    """).fetchall()
    hourly = connection.sql("""
        SELECT pattern_basis, pattern, hour_of_day, avg_hourly_trips FROM report_hourly
        WHERE zone_level = 'municipios' ORDER BY pattern_basis, pattern, hour_of_day
    """).fetchall()
    fit = connection.sql("SELECT * FROM report_fit").fetchone()
    ranking = connection.sql("""
        SELECT gap_rank, origin_zone_id, zone_name, actual_trips, estimated_on_observed_pairs, service_ratio, pair_coverage
        FROM report_ranking WHERE gap_rank IS NOT NULL ORDER BY gap_rank
    """).fetchall()
    mapping = connection.sql("SELECT province_code, geometry, weekend_change, service_ratio FROM report_map").fetchall()
    if not daily or not hourly or fit is None or not ranking or not mapping:
        raise QualityError("Report requires a complete Gold sample. Run scripts/build_gold.py first.")

    typical_map, gravity_map = choropleths(mapping)
    figures = {
        "typical_day_profile.png": hourly_profile(hourly),
        "typical_day_map.png": typical_map,
        "gravity_coverage.png": gravity_coverage([(row[-1], row[-2]) for row in ranking]),
        "gravity_map.png": gravity_map,
    }
    # Calculate network averages from national daily totals. OD-level averages
    # use pair-specific day counts, so summing those averages changes the denominator.
    means = connection.sql("""
        SELECT day_type, avg(total_trips), count(*) FROM report_days
        WHERE zone_level = 'municipios' GROUP BY day_type ORDER BY day_type
    """).fetchall()
    peak = max((row for row in hourly if row[0:2] == ("calendar", "weekday")), key=lambda row: row[3])
    gravity_k, eligible, observed, published_trips = fit
    below_estimate = sum(row[-2] < 1 for row in ranking)
    body = f"""
    <section aria-labelledby="typical">
      <h2 id="typical">BQ1. What does a typical day look like?</h2>
      <p>Across the municipality-level network, the weekday hourly profile peaks at
      <strong>{peak[2]:02d}:00</strong> with <strong>{peak[3] / 1e6:.2f} million trips</strong> on average.
      The sample contains weekdays and a weekend. No holiday pattern is estimated from this week.</p>
      {_table(('Calendar type', 'Observed days', 'Average daily trips'), ((kind.title(), days, f'{trips:,.0f}') for kind, trips, days in means))}
      {_figure(figures['typical_day_profile.png'], 'Two hourly trip charts compare calendar days and k-means groups.', 'The curves show the mean published trips per hour. K-means uses the hourly share of daily trips and fits two groups to seven days separately at each zoning level.')}
      {_figure(figures['typical_day_map.png'], 'Map of weekend change in originating trips by MITMA municipality zone.', 'The map compares average weekend and weekday volumes by origin. Orange-red indicates lower weekend demand. Grey indicates that a comparison is unavailable.')}
      <h3>Daily patterns at municipality level</h3>
      {_table(('Date', 'Calendar type', 'K-means group', 'Published trips', 'Peak hour'), ((day, kind.title(), group, f'{trips:,.0f}', f'{hour:02d}:00') for day, kind, group, trips, hour in daily))}
      <p class="note">Gold also stores hourly directed origin–destination averages and network profiles for districts and GAU. Each OD average uses the days on which that OD-hour was published.</p>
    </section>
    <section aria-labelledby="gravity">
      <h2 id="gravity">BQ2. Where are trips below the gravity estimate?</h2>
      <p>The municipality model compares observed trips with estimates based on origin population,
      destination business counts and squared distance between centroids. It fits
      <strong>k = {gravity_k:.6g}</strong> over <strong>{observed:,} published eligible pairs</strong>
      ({observed / eligible:.1%} of {eligible:,} eligible directed pairs, {published_trips:,.0f} trips).</p>
      <p><strong>{below_estimate:,} of {len(ranking):,}</strong> ranked origins fall below the estimate on the pairs that have a published flow.</p>
      {_figure(figures['gravity_map.png'], 'Map of observed-to-estimated trip ratios by municipality origin.', 'A ratio of 1× means observed and estimated volumes match on published pairs. Lower ratios are in orange-red, higher ratios in blue. Ratios at or above 40× share the darkest blue.')}
      {_figure(figures['gravity_coverage.png'], 'Origin coverage against observed-to-estimated trip ratio.', 'Each dot is an origin zone. Pair coverage is the share of eligible destinations with a published flow. The vertical scale is symmetric logarithmic to show both small and large ratios.')}
      <h3>Ten lowest ratios</h3>
      {_rank_table(ranking[:10])}
      <h3>Ten highest ratios</h3>
      {_rank_table(reversed(ranking[-10:]))}
      <p class="note">Rankings compare actual and estimated demand on the same published pairs.
      Actual trips sum the published observations, which can cover fewer than seven days for a pair.
      Pair coverage measures destinations, and the model can reflect gaps in publication as well as mobility.
      Use these results to identify where to investigate further.</p>
    </section>
    """
    document = f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1"><title>Spain mobility | Sprint 3</title>
    <style>{STYLE}</style></head><body><header><h1>Spain mobility</h1>
    <p>Sprint 3 · {start:%d %B %Y} to {end:%d %B %Y} · Sample week</p></header><main>{body}</main></body></html>"""
    output.mkdir(parents=True, exist_ok=True)
    with TemporaryDirectory(dir=output, prefix="report-") as temporary:
        stage = Path(temporary)
        for name, data in figures.items():
            (stage / name).write_bytes(data)
        (stage / "index.html").write_text(document, encoding="utf-8")
        for name in (*figures, "index.html"):
            (stage / name).replace(output / name)
    return output / "index.html"

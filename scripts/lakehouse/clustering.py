"""Cluster the small set of daily, national hourly profiles for each zoning level."""

import numpy as np
from sklearn.cluster import KMeans
from threadpoolctl import threadpool_limits

from .validation import QualityError


def label_daily_profiles(connection, dates):
    demand = connection.sql("SELECT * FROM daily_demand ORDER BY date").fetchall()
    published = connection.sql("SELECT date, hour_of_day, trips FROM daily_profiles ORDER BY date, hour_of_day").fetchall()
    if [row[1] for row in demand] != dates or [(day, hour) for day, hour, _ in published] != [
        (day, hour) for day in dates for hour in range(24)
    ]:
        raise QualityError("Clustering requires all 24 published hourly totals for every sample day")

    hourly_trips = np.array([trips for _, _, trips in published]).reshape(len(dates), 24)
    daily_totals = hourly_trips.sum(axis=1)
    if not np.isfinite(hourly_trips).all() or (hourly_trips < 0).any() or (daily_totals <= 0).any():
        raise QualityError("Daily profiles require finite volumes and positive daily totals")
    profiles = hourly_trips / daily_totals[:, None]
    with threadpool_limits(limits=1):
        labels = KMeans(n_clusters=2, random_state=0, n_init=20).fit_predict(profiles)
    if len(set(labels)) != 2:
        raise QualityError("The sample does not contain two distinct hourly patterns")

    # Give the clusters stable names by ordering them by mean daily volume.
    ordered = sorted(set(labels), key=lambda label: (daily_totals[labels == label].mean(), int(label)))
    cluster_ids = {label: number for number, label in enumerate(ordered, start=1)}
    connection.execute("""
        CREATE OR REPLACE TEMP TABLE daily_labels (
            zone_level VARCHAR, date DATE, day_type VARCHAR, cluster_id INTEGER, total_trips DOUBLE, peak_hour BIGINT
        )
    """)
    rows = [(level, day, day_type, cluster_ids[label], total, peak)
            for (level, day, day_type, total, peak), label in zip(demand, labels, strict=True)]
    connection.executemany("INSERT INTO daily_labels VALUES (?, ?, ?, ?, ?, ?)", rows)

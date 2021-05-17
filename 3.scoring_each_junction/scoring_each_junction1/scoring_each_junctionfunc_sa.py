import numpy as np
import pandas as pd

import geopandas as gpd
import psycopg2

# this script is used for sensitivity analysis, i.e. without taking weight function

# =============================================================================
# CATEGORY SCORE


def get_dist_score(pois_dists, dist, cat_dist_scores):
    """Assigns a simple distance based score for a given poi, we will take
    ranking into account later.

    pois_dists = all junction-poi distances
    dist = junction to current poi distance
    cat_dist_scores = category specific distance scores
    based on distance ranges (distance, score)
    """
    dist = int(round(dist))  # convert distance to integer
    for i in range(len(cat_dist_scores)):
        # for every distance category in dist_scores (increasing in distance),
        # check if distance to poi is larger than that distance category
        # if so, return that range's score (the function no longer runs)
        if dist >= cat_dist_scores[i][0]:
            return cat_dist_scores[i][1]


def adjust_by_rank(dist_score, rank, cat_rank_weights):
    """Takes ranking into Account.
    dist_score = output of get_dist_score
    rank = specific poi's rank / corresponds to value of i
    rank_weights = category specific rank based weights
    """
    adjusted_score = dist_score * cat_rank_weights[rank]
    return adjusted_score


def cat_score(df, type2_array, cat_dist_scores, cat_rank_weights):
    """Use get_dist_score() and adjust_by_rank()
    """
    cat_score = 0  # initialise the score

    pois = df.loc[df['type2_en'].isin(type2_array)]  # get pois of category

    if len(pois) == 0:
        return cat_score  # return category score of 0 if no pois found

    else:
        pois_dists = pois['distance'].values  # all junction-poi distances
        pois_dists = np.sort(pois_dists)

        if (len(pois_dists)) < len(cat_rank_weights):
            nb_pois_used = len(pois_dists)  # for small number of pois
        else:
            nb_pois_used = len(cat_rank_weights)  # limit number of pois used

        for i in range(nb_pois_used):
            dist_score = get_dist_score(pois_dists, pois_dists[i], cat_dist_scores)
            score = adjust_by_rank(dist_score, i, cat_rank_weights)
            cat_score = cat_score + score  # add individual poi's score

        return cat_score

# =============================================================================
# JUNCTION SCORE


    score_shop =  cat_score(df, shop_types, shop_dist_scores, shop_weights)
    score_major = cat_score(df, major_transport_types, major_transport_dist_scores,
                      major_transport_weights)
    score_bus = cat_score(df, bus_transport_types, bus_transport_dist_scores,
                          bus_transport_weights)
    score_restaurant = cat_score(df, restaurant_types, restaurant_dist_scores,
                                 restaurant_weights)
    score_entertainment = cat_score(df, entertainment_types,
                                    entertainment_dist_scores,
                                    entertainment_weights)
    score_park = cat_score(df, park_types, park_dist_scores, park_weights)
    score_sport = cat_score(df, sport_types, sport_dist_scores, sport_weights)
    score_school = cat_score(df, school_types, school_dist_scores,
                             school_weights)
    score_domestic = cat_score(df, domestic_types, domestic_dist_scores,
                               domestic_weights)
    score_health = cat_score(df, health_types, health_dist_scores,
                             health_weights)

    junction_score = score_shop + score_major + score_bus + score_restaurant \
        + score_entertainment + score_park + score_sport + score_school \
        + score_domestic + score_health

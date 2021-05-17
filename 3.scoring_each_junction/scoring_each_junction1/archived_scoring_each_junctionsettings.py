# =============================================================================
# SHOP
shop_types = [
             'Shop',
             'Comprehensive market',
             'Convenience store / convenience store',
             'Shopping related sites'
             ]
# the shop_dist_scores setting means that within 0-100 distance, the shop gets a score of 10,
# then 101-200, score 8, 201-300 score 5, 301-400 score 3, anything beyond 400, 0.
shop_dist_scores = [(400, 0), (300, 3), (200, 5), (100, 8), (0, 10)]  # distancebased scores
shop_weights = [1, 0.5, 0.3, 0.1, 0.1]  # the length of the weights determines
                                        # the nb of pois considered
#score_shop =  cat_score(df, shop_types, shop_dist_scores, shop_weights)

# =============================================================================
# STATION
major_transport_types = [
                         'TRAIN STATION',
                         'subway station'
                         ]
major_transport_dist_scores = [(200, 7), (0, 10)]  # distancebased scores
major_transport_weights = [5, 0]
# the weight for this one is set very high as we think it's very important to 
# reach a major transport closer, and the nearest is the most important
# once the closest is reached, the rest is meaningless
#score_station = cat_score(df, major_transport_types, major_transport_dist_scores, major_transport_weights)

# PUBLIC TRANSPORT _ Bus Stop
bus_transport_types = ['bus stop']
bus_transport_dist_scores = [(200, 7), (0, 10)]  # distancebased scores
bus_transport_weights = [1, 0.5, 0.3, 0.1, 0.1]
#score_bus = cat_score(df, bus_transport_types, bus_transport_dist_scores, bus_transport_weights)

# =============================================================================
# RESTAURANT
restaurant_types = [
                    'Restaurant',
                    'Fast-food restaurant',
                    'Cafe',
                    'Foreign Restaurants',
                    'Food related sites',
                    'Casual dining options'
                    ]
restaurant_dist_scores = [(200, 1), (0, 2)]  # distancebased scores
restaurant_weights = [0.5, 0.5, 0.5, 0.5, 0.3, 0.3, 0.3, 0.3]
#score_restaurant = cat_score(df, restaurant_types, restaurant_dist_scores, restaurant_weights)

# =============================================================================
# ENTERTAINMENT
entertainment_types = [
                        'Entertainment',
                        'Theater'
                        ]
entertainment_dist_scores = [(200, 1), (0, 2)]  # distancebased scores
entertainment_weights = [0.5, 0.5, 0.5, 0.5, 0.3, 0.3, 0.3, 0.3]
#score_entertainment = cat_score(df, entertainment_types, entertainment_dist_scores, entertainment_weights)

# =============================================================================
# PARKS
'''parks have been removed during the data cleaning phase '''

# =============================================================================
# SPORTS COMPLEX

sport_types = [
              'Sports Complex',
              'Sports and leisure establishments'
              ]
sport_dist_scores = [(200, 1), (0, 2)]  # distancebased scores
sport_weights = [0.5, 0.5, 0.5, 0.5, 0.3, 0.3, 0.3, 0.3]
#score_sport = cat_score(df, sport_types, sport_dist_scores, sport_weights)

# =============================================================================
# SCHOOL
school_types = [
              'Sports Complex',
              'Sports and leisure establishments'
              ]
school_dist_scores = [(200, 1), (0, 2)]  # distancebased scores
school_weights = [0.5, 0.5, 0.5, 0.5, 0.3, 0.3, 0.3, 0.3]
#score_school = cat_score(df, school_types, school_dist_scores, school_weights)

# =============================================================================
# DOMESTIC SERVICES
domestic_types = [
              'Beauty salon',
              'Photography print shop'
              ]
domestic_dist_scores = [(200, 1), (0, 2)]  # distancebased scores
domestic_weights = [0.5, 0.5, 0.5, 0.5, 0.3, 0.3, 0.3, 0.3]
#score_domestic = cat_score(df, domestic_types, domestic_dist_scores, domestic_weights)

# =============================================================================
# HEALTHCARE
health_types = [
              'general Hospital',
              'clinic',
              'Specialist Hospital'
              ]
health_dist_scores = [(200, 1), (0, 2)]  # distancebased scores
health_weights = [0.5, 0.5, 0.5, 0.5, 0.3, 0.3, 0.3, 0.3]
#score_health = cat_score(df, health_types, health_dist_scores, health_weights)

# =============================================================================

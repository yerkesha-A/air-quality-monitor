import unittest
from air_logic import above_threshold, claim_id, valid_coordinates


class AirLogicTest(unittest.TestCase):
    def test_threshold_boundaries_and_missing_data(self):
        self.assertFalse(above_threshold(None, 100))
        self.assertFalse(above_threshold(float('nan'), 100))
        self.assertFalse(above_threshold(True, 25))
        self.assertFalse(above_threshold(-1, 100))
        self.assertFalse(above_threshold(50, 10))
        self.assertFalse(above_threshold(99, 100))
        self.assertTrue(above_threshold(100, 100))
        self.assertTrue(above_threshold(500, 300))

    def test_coordinates(self):
        self.assertTrue(valid_coordinates({'latitude': 43.2, 'longitude': 76.9}))
        for place in [None, {}, {'latitude': 100, 'longitude': 0},
                      {'latitude': 0, 'longitude': float('inf')},
                      {'latitude': True, 'longitude': 1}]:
            self.assertFalse(valid_coordinates(place))

    def test_hourly_deduplication_includes_place_and_threshold(self):
        self.assertEqual(claim_id('a', 3601, 100), claim_id('a', 3999, 100))
        self.assertNotEqual(claim_id('a', 3601, 100), claim_id('b', 3601, 100))
        self.assertNotEqual(claim_id('a', 3601, 100), claim_id('a', 7201, 100))
        self.assertNotEqual(claim_id('a', 3601, 100), claim_id('a', 3601, 150))


if __name__ == '__main__':
    unittest.main()

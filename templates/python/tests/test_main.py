import unittest

from app.main import message


class MainTest(unittest.TestCase):
    def test_message(self) -> None:
        self.assertEqual(message(), "hello")


if __name__ == "__main__":
    unittest.main()

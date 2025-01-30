from pathlib import Path

import pandas as pd
from geopy.extra.rate_limiter import RateLimiter
from geopy.geocoders import Nominatim
from tqdm import tqdm

tqdm.pandas()

data_dir = Path("data/dataset")

# Converting latitude and longitude to address
geolocator = Nominatim(user_agent="Photon")
geocode = RateLimiter(geolocator.reverse, min_delay_seconds=1)


def coord_to_address(
    df: pd.DataFrame, cols: tuple[str, str] = ("latitude", "longitude")
) -> pd.DataFrame:
    # Extract address components into separate columns
    def extract_address_components(row):
        location = geocode((row[cols[0]], row[cols[1]]), language="en")
        if location:
            address = location.raw.get("address", {})
            city = address.get(
                "city", address.get("town", address.get("village", None))
            )
            country = address.get("country", None)
            return city, country
        return None, None

    df[["city", "country"]] = df.progress_apply(
        lambda x: pd.Series(extract_address_components(x)), axis=1
    )
    return df


if __name__ == "__main__":
    df = pd.read_csv(data_dir / "coords.csv", names=["latitude", "longitude"])
    df = df.sample(n=1, random_state=42)
    # Convert coordinates to address
    df = coord_to_address(df)

    df.to_csv(data_dir / "coords_with_address.csv", index=False)

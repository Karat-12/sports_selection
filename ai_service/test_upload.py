import requests

def upload_videos(url, video_paths):
    files = [('videos', (open(v, 'rb'))) for v in video_paths]

    response = requests.post(url, files=files)
    if response.ok:
        print("Response JSON:")
        print(response.json())
    else:
        print(f"Request failed with status code {response.status_code}: {response.text}")

if __name__ == "__main__":
    # Change URL if your Flask server runs elsewhere
    api_url = "http://127.0.0.1:5000/upload_multiple"

    # List of local video file paths to upload
    videos = [
        r'D:\sports_person_selection\pushups.mp4',
        r'D:\sports_person_selection\squats.mp4',
        r'D:\sports_person_selection\jumpingjacks.mp4'
    ]

    upload_videos(api_url, videos)

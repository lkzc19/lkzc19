import requests

if __name__ == '__main__':
    response = requests.request(
        method="GET",
        url=f'https://api.caiyunapp.com/v2.6/oktMvXITa21JM2Dc/101.6656,39.2072/hourly?hourlysteps=1&adcode=350104',
    ).json()
    print(response)

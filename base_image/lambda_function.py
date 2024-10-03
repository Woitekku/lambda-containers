import json
import numpy as np
import requests

def lambda_handler(event, context):
    # Sample NumPy usage
    array = np.array([1, 2, 3, 4, 5])
    mean = np.mean(array)

    # Sample Requests usage
    response = requests.get("https://api.github.com")

    return {
        'statusCode': 200,
        'body': json.dumps({
            'mean': mean,
            'github_api_status': response.status_code
        })
    }

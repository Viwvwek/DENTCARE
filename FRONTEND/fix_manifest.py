import re
import os

path = r'C:\Users\vivek\AppData\Local\Pub\Cache\hosted\pub.dev\tflite_v2-1.0.0\android\src\main\AndroidManifest.xml'
if os.path.exists(path):
    with open(path, 'r') as f:
        content = f.read()
    # Remove package="..."
    new_content = re.sub(r'package="[^"]*"', '', content)
    with open(path, 'w') as f:
        f.write(new_content)
    print("Successfully fixed manifest")
else:
    print("Manifest path not found")

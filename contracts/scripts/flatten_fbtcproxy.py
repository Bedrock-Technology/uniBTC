from brownie import *
from pathlib import Path

import time
import pytest

def main():
    info = FBTCProxy.get_verification_info()
    data=open("/Users/eben/Desktop/flatten-FBTCProxy.txt",'w+') 
    print(FBTCProxy._flattener.flattened_source,file=data)
    data.close()
    #print(FBTCProxy._flattener.flattened_source)
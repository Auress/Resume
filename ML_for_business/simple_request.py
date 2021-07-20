from urllib import request
import urllib.request
import json


def get_prediction(molecule_name, atom_index_0, atom_index_1, atom_type):
    body = {'molecule_name': molecule_name,
            'atom_index_0': atom_index_0,
            'atom_index_1': atom_index_1,
            'atom_type': atom_type}

    myurl = "http://localhost:5000/predict"
    req = urllib.request.Request(myurl)
    req.add_header('Content-Type', 'application/json; charset=utf-8')
    jsondata = json.dumps(body)
    jsondataasbytes = jsondata.encode('utf-8')   # needs to be bytes
    req.add_header('Content-Length', len(jsondataasbytes))
    #print (jsondataasbytes)
    response = urllib.request.urlopen(req, jsondataasbytes)
    return json.loads(response.read())['predictions']

if __name__=='__main__':
    molecule_name = 'dsgdb9nsd_122869'
    atom_index_0 = 14
    atom_index_1 = 3
    atom_type = '1JHC'
    preds = get_prediction(molecule_name, atom_index_0, atom_index_1, atom_type)
    print(preds)

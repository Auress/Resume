from flask import Flask, render_template, redirect, url_for, request
from flask_wtf import FlaskForm
from requests.exceptions import ConnectionError
from wtforms import StringField
from wtforms.validators import DataRequired

import urllib.request
import json

class ClientDataForm(FlaskForm):
    molecule_name = StringField('Molecule name', validators=[DataRequired()])
    atom_index_0 = StringField('Atom index 0', validators=[DataRequired()])
    atom_index_1 = StringField('Atom index 1', validators=[DataRequired()])
    atom_type = StringField('Atom type', validators=[DataRequired()])

app = Flask(__name__)
app.config.update(
    CSRF_ENABLED=True,
    SECRET_KEY='you-will-never-guess',
)

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

@app.route("/")
def index():
    return render_template('index.html')


@app.route('/predicted/<response>')
def predicted(response):
    response = json.loads(response)
    print(response)
    return render_template('predicted.html', response=response)


@app.route('/predict_form', methods=['GET', 'POST'])
def predict_form():
    form = ClientDataForm()
    data = dict()
    if request.method == 'POST':
        data['molecule_name'] = request.form.get('molecule_name')
        data['atom_index_0'] = int(request.form.get('atom_index_0'))
        data['atom_index_1'] = int(request.form.get('atom_index_1'))
        data['atom_type'] = request.form.get('atom_type')

        try:
            response = str(get_prediction(data['molecule_name'],
                                      int(data['atom_index_0']),
                                      int(data['atom_index_1']),
                                      data['atom_type']))
            print(response)
        except ConnectionError:
            response = json.dumps({"error": "ConnectionError"})
        return redirect(url_for('predicted', response=response))
    return render_template('form.html', form=form)


if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5001, debug=True)
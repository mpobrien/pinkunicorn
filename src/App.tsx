import React, {useState, useEffect} from 'react';
import './App.css';
import Login from './Login';
import classnames from 'classnames';
import * as Realm from 'realm-web';
import copy from './copy.png';

const LOCAL_STORAGE_KEY = 'stitchutils_app';

function Lookup() {
  const [appID, setAppID] = useState<string>();
  const [error, setError] = useState<string | undefined>();

  const lookup = () => {
    setError(undefined);
    fetch('http://localhost:8080/api/private/v1.0/app/' + appID, {
      mode: 'cors',
    })
      .then(response => response.json())
      .then(info => {
        console.log(info);
      })
      .catch(err => {
        setError(err.toString());
      });
  };

  return (
    <div>
      <div className="input-group">
        <label>App ID</label>
        <input
          type="text"
          value={appID}
          onChange={e => setAppID(e.target.value)}
        />
        <button onClick={lookup}>Find</button>
      </div>
      {error && <div className="error">{error}</div>}
    </div>
  );
}

function App() {
  const [app, setApp] = useState<Realm.App>();

  const storeAppInfo = (appID: string, baseURL: string): void => {
    localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify({appID, baseURL}));
  };

  const logout = async () => {
    if (app && app.currentUser) {
      try {
        await app.currentUser.logOut();
      } catch {
        console.log('deleting session failed');
      }
      localStorage.removeItem(LOCAL_STORAGE_KEY);
      setApp(undefined);
    }
  };

  useEffect(() => {
    try {
      const app: Realm.App = new Realm.App({
        id: 'pink-unicorn-bvzgq',
      });
      if (!app.currentUser) {
        // not actually logged in
        localStorage.removeItem(LOCAL_STORAGE_KEY);
      }
      setApp(app as Realm.App);
    } catch (e) {}
  }, []);

  return (
    <div className="App">
      {app && app.currentUser ? (
        <div>
          <div>
            logged in as:&nbsp;
            <b>{app.currentUser.id}</b>
            &nbsp; on <b>{app.id}</b>
            &nbsp;<button onClick={logout}>log out</button>
          </div>
          <br />
          <hr />
          <Board user={app.currentUser}></Board>
        </div>
      ) : (
        <Login setApp={setApp} />
      )}
    </div>
  );
}

interface BoardProps {
  //app: Realm.App;
  user: Realm.User;
}

type Component = any;

const rgbToHex = function(rgb: number) {
  var hex = Number(rgb).toString(16);
  if (hex.length < 2) {
    hex = '0' + hex;
  }
  return hex;
};

function Board(props: BoardProps) {
  const [shapes, setShapes] = React.useState<any>();
  const canvasRef = React.useRef(null);

  const canvasWidth = 500;
  const canvasHeight = 500;
  const fetchShapes = async function() {
    const mongodb = props.user.mongoClient('mongodb-atlas');
    const components = await mongodb
      .db('pinkunicorn')
      .collection<Component>('Component')
      .find();
    console.log(components);
    const canvas = canvasRef.current;
    if (!canvas) {
      return;
    }
    const context = (canvas as HTMLCanvasElement).getContext('2d');
    if (!context) {
      return;
    }
    context.clearRect(0, 0, canvasWidth, canvasHeight);

    for (var i = 0; i < components.length; i++) {
      const component = components[i];
      if (component.color) {
        const hexColor = rgbToHex(component.color);
        context.strokeStyle = '#' + hexColor;
      } else {
        context.strokeStyle = '#000000';
      }

      if (component.shape == 'circle') {
        context.beginPath();
        context.arc(component.x, component.y, component.x2, 0, 2 * Math.PI);
        context.stroke();
      } else if (component.shape == 'rectangle') {
        context.beginPath();
        context.strokeRect(
          component.x,
          component.y,
          component.x2,
          component.y2,
        );
        context.stroke();
      }
    }
  };

  return (
    <div>
      <button onClick={fetchShapes}>Fetch</button>
      <div>
        <canvas
          width={canvasWidth}
          height={canvasHeight}
          ref={canvasRef}></canvas>
      </div>
    </div>
  );
  //props.storeAppInfo(appID, baseURL);
}

export default App;

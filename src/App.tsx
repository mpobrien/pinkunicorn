import React, {useState, useEffect} from 'react';
import './App.css';
import Login from './Login';
import classnames from 'classnames';
import * as Realm from 'realm-web';
import copy from './copy.png';
import {CompactPicker} from 'react-color';
import BSON from 'bson';

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

const hex2Rgb = (hex: string | undefined) => {
  if (!hex) {
    return 0;
  }
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return r * 65536 + g * 256 + b;
};

function redraw(
  context: CanvasRenderingContext2D,
  components: any[],
  canvasWidth: number,
  canvasHeight: number,
  clear: boolean,
) {
  if (clear) {
    context.clearRect(0, 0, canvasWidth, canvasHeight);
  }
  context.strokeStyle = '#000000';
  context.strokeRect(0, 0, canvasWidth, canvasHeight);
  context.stroke();

  for (var i = 0; i < components.length; i++) {
    const component = components[i];
    context.strokeStyle = '#000000';
    if (component.strokeColor) {
      const hexColor = rgbToHex(component.strokeColor);
      context.strokeStyle = '#' + hexColor;
    }

    if (component.shape == 'path') {
      context.beginPath();
      if (component.points.length > 0) {
        context.moveTo(component.points[0].x, component.points[0].y);
      }
      for (var j = 0; j < component.points.length; j++) {
        context.lineTo(component.points[j].x, component.points[j].y);
      }
      context.stroke();
    }
    if (component.shape == 'circle') {
      const distance = Math.sqrt(
        Math.pow(
          component.right - component.x + (component.height - component.y),
          2,
        ),
      );
      context.beginPath();
      const radiusX = Math.abs(component.right - component.left) / 2;
      const radiusY = Math.abs(component.bottom - component.top) / 2;
      context.ellipse(
        (component.right - component.left) / 2 + component.left,
        (component.bottom - component.top) / 2 + component.top,
        radiusX,
        radiusY,
        0,
        0,
        2 * Math.PI,
      );
      context.stroke();
    } else if (component.shape == 'rectangle') {
      context.beginPath();
      context.strokeRect(
        component.left,
        component.top,
        component.right - component.left,
        component.bottom - component.top,
      );
      context.stroke();
    }
  }
}

interface Point {
  x: number;
  y: number;
}

function Board(props: BoardProps) {
  const [tool, setTool] = React.useState<string>('circle');
  const [shapes, setShapes] = React.useState<any>();
  const [newShape, setNewShape] = React.useState<any>();
  const [points, setPoints] = React.useState<any>();
  const [fetched, setFetched] = React.useState<boolean>();
  const [color, setColor] = React.useState<string>();
  const canvasRef = React.useRef<HTMLCanvasElement>(null);
  const contextRef = React.useRef<CanvasRenderingContext2D>();
  const [startPoint, setStartPoint] = React.useState<Point | null>();
  const [isDrawing, setIsDrawing] = React.useState<boolean>();

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
    setShapes(components);
    redraw(context, components, canvasWidth, canvasHeight, true);
  };

  useEffect(() => {
    if (!fetched) {
      fetchShapes();
      setFetched(true);
    }
    const canvas = canvasRef.current;
    if (!canvas) {
      return;
    }
    const canvasHTML = canvas as HTMLCanvasElement;
    const context = canvasHTML.getContext('2d');
    if (context) {
      contextRef.current = context;
    }
  }, []);

  const startDrawing = (
    event: React.MouseEvent<HTMLCanvasElement, MouseEvent>,
  ) => {
    if (!contextRef.current || !canvasRef.current) {
      return;
    }
    setIsDrawing(true);
    redraw(contextRef.current, shapes, canvasWidth, canvasHeight, true);
    setStartPoint({
      x: event.clientX - canvasRef.current.getBoundingClientRect().x,
      y: event.clientY - canvasRef.current.getBoundingClientRect().y,
    });
  };

  const finishDrawing = async function() {
    if (!newShape || !isDrawing) {
      return;
    }
    setIsDrawing(false);
    setStartPoint(null);
    setPoints([]);
    const mongodb = props.user.mongoClient('mongodb-atlas');

    let [left, right, top, bottom] = [
      newShape.left,
      newShape.right,
      newShape.top,
      newShape.bottom,
    ];

    newShape.left = new BSON.Double(Math.min(left, right));
    newShape.right = new BSON.Double(Math.max(left, right));

    newShape.top = new BSON.Double(Math.min(top, bottom));
    newShape.bottom = new BSON.Double(Math.max(top, bottom));
    if (newShape.shape == 'path') {
      newShape.left = new BSON.Double(
        Math.min(...newShape.points.map((p: any) => p.x)),
      );
      newShape.right = new BSON.Double(
        Math.max(...newShape.points.map((p: any) => p.x)),
      );

      newShape.top = new BSON.Double(
        Math.min(...newShape.points.map((p: any) => p.y)),
      );
      newShape.bottom = new BSON.Double(
        Math.max(...newShape.points.map((p: any) => p.y)),
      );
    }

    const components = await mongodb
      .db('pinkunicorn')
      .collection<Component>('Component')
      .insertOne(newShape);
  };
  const draw = (event: React.MouseEvent<HTMLCanvasElement, MouseEvent>) => {
    if (
      !isDrawing ||
      !contextRef.current ||
      !canvasRef.current ||
      !startPoint
    ) {
      return;
    }
    const endPoint = {
      x: event.clientX - canvasRef.current.getBoundingClientRect().x,
      y: event.clientY - canvasRef.current.getBoundingClientRect().y,
    };
    let newShape: any;
    if (tool == 'path') {
      let newPoints = (points || []).concat([
        {x: new BSON.Double(endPoint.x), y: new BSON.Double(endPoint.y)},
      ]);
      newShape = {
        _id: new BSON.ObjectId(),
        left: startPoint.x,
        top: startPoint.y,
        z: new BSON.Double(0),
        right: endPoint.x,
        bottom: endPoint.y,
        strokeColor: hex2Rgb(color),
        strokeWidth: new BSON.Double(1),
        points: newPoints,
        shape: 'path',
      };
      setPoints(newPoints);
    } else if (tool == 'line') {
      newShape = {
        _id: new BSON.ObjectId(),
        left: Math.min(startPoint.x, endPoint.x),
        right: Math.max(startPoint.x, endPoint.x),
        top: Math.min(startPoint.y, endPoint.y),
        bottom: Math.max(startPoint.y, endPoint.y),
        z: new BSON.Double(0),
        strokeColor: hex2Rgb(color),
        strokeWidth: new BSON.Double(1),
        shape: 'path',
        points: [
          {x: new BSON.Double(startPoint.x), y: new BSON.Double(startPoint.y)},
          {x: new BSON.Double(endPoint.x), y: new BSON.Double(endPoint.y)},
        ],
      };
    } else {
      newShape = {
        _id: new BSON.ObjectId(),
        left: startPoint.x,
        top: startPoint.y,
        z: new BSON.Double(0),
        right: endPoint.x,
        bottom: endPoint.y,
        strokeColor: hex2Rgb(color),
        strokeWidth: new BSON.Double(1),
        shape: tool,
      };
    }
    setNewShape(newShape);
    redraw(contextRef.current, shapes, canvasWidth, canvasHeight, true);
    redraw(contextRef.current, [newShape], canvasWidth, canvasHeight, false);
  };

  return (
    <div>
      <button onClick={fetchShapes}>Refresh Board</button>
      <br />
      <br />
      <select value={tool} onChange={e => setTool(e.target.value)}>
        <option value="circle">&#9711;</option>
        <option value="rectangle">&#9634;</option>
        <option value="path">&#9998;</option>
        <option value="line">&#9144;</option>
      </select>
      <div>
        <CompactPicker color={color} onChangeComplete={c => setColor(c.hex)} />
      </div>
      <div>
        <canvas
          width={canvasWidth}
          height={canvasHeight}
          ref={canvasRef}
          onMouseDown={startDrawing}
          onMouseUp={finishDrawing}
          onMouseMove={draw}></canvas>
      </div>
    </div>
  );
  //props.storeAppInfo(appID, baseURL);
}

export default App;

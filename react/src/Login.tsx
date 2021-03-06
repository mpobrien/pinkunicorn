import * as Realm from 'realm-web';
import React, {useState} from 'react';

enum AuthProvider {
  UserPassword = 'username/password',
  Anonymous = 'anonymous',
  APIKey = 'apikey',
}

interface LoginProps {
  setApp?: (app: Realm.App) => void;
}

export default function Login(props: LoginProps) {
  const [username, setUsername] = useState<string>('');
  const [password, setPassword] = useState<string>('');
  const [loginError, setLoginError] = useState<string>('');

  const loginAnonymous = async () => {
    setLoginError('');
    const app: Realm.App = new Realm.App({id: 'pink-unicorn-bvzgq'});
    const credentials = Realm.Credentials.anonymous();
    try {
      // Authenticate the user
      const user: Realm.User = await app.logIn(credentials);
      if (props.setApp) {
        props!.setApp(app);
      }
      return user;
    } catch (err) {
      console.log(err);
    }
  };

  const loginAdmin = async (username: string, password: string) => {
    setLoginError('');
    const app: Realm.App = new Realm.App({id: 'pink-unicorn-bvzgq'});
    const credentials = Realm.Credentials.emailPassword(username, password);
    try {
      // Authenticate the user
      const user: Realm.User = await app.logIn(credentials);
      if (props.setApp) {
        props!.setApp(app);
      }
      return user;
    } catch (err) {
      console.log(err);
    }
  };

  return (
    <form method="post" action="/form" autoComplete="off">
      <div></div>
      {/*
      <div className="input-group">
        <br />
        <label>Auth Provider</label>
        <select
          onChange={e => setAuthProvider(e.target.value as AuthProvider)}
          value={authProvider}>
          {[
            AuthProvider.UserPassword,
            AuthProvider.Anonymous,
            AuthProvider.APIKey,
          ].map(b => (
            <option value={b} key={b}>
              {b}
            </option>
          ))}
        </select>
      </div>
      {authProvider === AuthProvider.APIKey && (
        <div className="input-group">
          <label>API Key</label>
          <input
            type="text"
            onChange={e => setApiKey(e.target.value)}
            value={apiKey}
          />
        </div>
      )}
      {authProvider === AuthProvider.UserPassword && (
        <div className="input-group">
          <label>Username</label>
          <input
            type="text"
            onChange={e => setUsername(e.target.value)}
            value={username}
          />
        </div>
      )}
      {authProvider === AuthProvider.UserPassword && (
        <div className="input-group">
          <label>Password</label>
          <input
            type="password"
            onChange={e => setPassword(e.target.value)}
            value={password}
          />
        </div>
      )}
        */}

      <div className="auth-wrapper">
        <h3>User Login</h3>
        <button
          onClick={e => {
            e.preventDefault();
            loginAnonymous();
          }}>
          log in
        </button>
      </div>
      <div className="auth-wrapper">
        <h3>Admin Login</h3>
        <div className="input-group">
          <label>Username</label>
          <input
            type="text"
            onChange={e => setUsername(e.target.value)}
            value={username}
          />
        </div>
        <div className="input-group">
          <label>Password</label>
          <input
            type="password"
            onChange={e => setPassword(e.target.value)}
            value={password}
          />
        </div>
        <button
          onClick={e => {
            e.preventDefault();
            loginAdmin(username, password);
          }}>
          log in
        </button>
      </div>
      {loginError && <div className="error">{loginError}</div>}
    </form>
  );
}

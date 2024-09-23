import React from 'react';
import ReactDOM from 'react-dom/client';
import * as Body from './body.res.js';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <Body.make />
  </React.StrictMode>
)
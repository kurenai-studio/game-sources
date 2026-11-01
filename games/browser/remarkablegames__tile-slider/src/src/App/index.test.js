import React from 'react';
import { render, unmountComponentAtNode } from 'react-dom';

window.ga = jest.fn();
window.requirejs = jest.fn();

it('renders without crashing', () => {
  const App = require('.').default;
  const div = document.createElement('div');
  render(<App />, div);
  unmountComponentAtNode(div);
});

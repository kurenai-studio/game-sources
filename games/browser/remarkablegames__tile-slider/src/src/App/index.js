import React, { Component } from 'react';
import TileSlider from '../TileSlider';
import './styles.css';

export default class App extends Component {
  render() {
    return (
      <main className="App__main" role="main">
        <h1 className="App__h1 text-center">Tile Slider</h1>
        <TileSlider size={3} />
      </main>
    );
  }
}

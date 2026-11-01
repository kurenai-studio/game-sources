import React, { Component } from 'react';
import { trackEvent } from '../helpers/ga';
import './styles.css';

/**
 * Generates an array of numbers starting at 1.
 *
 * @param  {Number} size
 * @return {Array}
 */
const generateNumbers = size =>
  Array.apply(null, { length: size }).map((_, index) => index + 1);

/**
 * Shuffles an array.
 *
 * @param  {Array}   array
 * @param  {Boolean} [shouldMutate=false]
 * @return {Array}
 */
const shuffleArray = (array = [], shouldMutate = false) => {
  const arr = shouldMutate ? array : array.slice();
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    const temp = arr[i];
    arr[i] = arr[j];
    arr[j] = temp;
  }
  return arr;
};

/**
 * Generates solution.
 *
 * @param  {Number} size
 * @return {Object}
 */
const generateSolution = size => {
  const numbers = generateNumbers(size ** 2 - 1);
  numbers.push(null);
  const solution = [];

  while (numbers.length) {
    solution.push(numbers.splice(0, size));
  }

  return {
    solution,
    solutionJSON: JSON.stringify(solution),
  };
};

/**
 * Generates puzzle.
 *
 * @param  {Number} size
 * @return {Object}
 */
const generatePuzzle = size => {
  if (size < 2) {
    throw Error('Puzzle size must be an integer greater than 1.');
  }

  const numbers = generateNumbers(size ** 2 - 1);
  const random = shuffleArray(generateNumbers(size ** 2 - 1));

  // make sure numbers are random
  if (JSON.stringify(random) === JSON.stringify(numbers)) {
    return generatePuzzle(size);
  }

  random.push(null);
  const puzzle = [];

  while (random.length) {
    puzzle.push(random.splice(0, size));
  }

  return { puzzle };
};

export default class TileSlider extends Component {
  state = {
    size: this.props.size,
    ...generatePuzzle(this.props.size),
    ...generateSolution(this.props.size),
  };

  /**
   * Swaps tile with empty one when clicked.
   *
   * @param {SyntheticEvent}
   */
  handleClick = ({ target }) => {
    trackEvent('puzzle', 'click');

    const puzzle = this.state.puzzle.map(row => row.slice());
    let { value, x, y } = target.dataset;
    value = parseInt(value, 10);
    x = parseInt(x, 10);
    y = parseInt(y, 10);

    if (puzzle[y][x - 1] === null) {
      puzzle[y][x - 1] = value;
    } else if (puzzle[y][x + 1] === null) {
      puzzle[y][x + 1] = value;
    } else if (puzzle[y - 1] && puzzle[y - 1][x] === null) {
      puzzle[y - 1][x] = value;
    } else if (puzzle[y + 1] && puzzle[y + 1][x] === null) {
      puzzle[y + 1][x] = value;
    } else {
      return;
    }

    puzzle[y][x] = null;
    this.setState({ puzzle }, () => {
      // check win state
      if (JSON.stringify(puzzle) === this.state.solutionJSON) {
        trackEvent('puzzle', 'solve');
        setTimeout(() => alert('Puzzle solved!'), 100);
      }
    });
  };

  /**
   * Shuffles current puzzle.
   */
  shufflePuzzle = () => {
    trackEvent('puzzle', 'shuffle');
    this.setState(({ puzzle }) => generatePuzzle(puzzle.length));
  };

  /**
   * Generates new puzzle and solution.
   *
   * @param {SyntheticEvent} event
   */
  newPuzzle = event => {
    event.preventDefault();
    trackEvent('puzzle', 'new', undefined, this.state.size);
    this.setState(({ size }) => ({
      ...generatePuzzle(size),
      ...generateSolution(size),
    }));
  };

  /**
   * Updates size (used when generating a new puzzle).
   *
   * @param {SyntheticEvent}
   */
  changeSize = ({ target }) => {
    const size = parseInt(target.value, 10);
    if (size > 1) {
      this.setState({ size });
    }
  };

  /**
   * Navigates puzzle using arrow keys.
   *
   * @param {SyntheticEvent}
   */
  handleKeyDown = ({ key, target }) => {
    // Get x, y dataset from target element.
    let { x, y } = target.dataset;

    // Convert x and y to integers.
    x = parseInt(x, 10);
    y = parseInt(y, 10);

    switch (key) {
      case 'ArrowUp':
        y -= 1;
        break;
      case 'ArrowDown':
        y += 1;
        break;
      case 'ArrowLeft':
        x -= 1;
        break;
      case 'ArrowRight':
        x += 1;
        break;
      default:
        return;
    }

    const button = this.tbody.querySelector(`[data-x="${x}"][data-y="${y}"]`);
    if (button) setTimeout(() => button.focus());
  };

  render() {
    const { puzzle, size } = this.state;

    return (
      <div className="text-center">
        <table className="block-center">
          <tbody ref={element => (this.tbody = element)}>
            {puzzle &&
              puzzle.map((rows, y) => (
                <tr key={y}>
                  {rows.map((value, x) => (
                    <td key={x}>
                      <button
                        className="TileSlider__button"
                        data-value={value}
                        data-x={x}
                        data-y={y}
                        onClick={this.handleClick}
                        onKeyDown={this.handleKeyDown}
                      >
                        {value}
                      </button>
                    </td>
                  ))}
                </tr>
              ))}
          </tbody>
        </table>
        <br />

        <button onClick={this.shufflePuzzle}>Shuffle Puzzle</button>
        <br />
        <br />

        <form className="TileSlider__form" onSubmit={this.newPuzzle}>
          <label>
            Size (Row/Column):&nbsp;
            <input
              className="TileSlider__input"
              min={2}
              onChange={this.changeSize}
              type="number"
              value={size}
            />
            &nbsp;
            <input type="submit" value="New Puzzle" />
          </label>
        </form>
      </div>
    );
  }
}

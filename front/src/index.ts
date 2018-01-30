import * as ReactDOM from 'react-dom';

// Reexport react-dom.
export {
    ReactDOM,
};

export function loadGameStartControl() {
    return import('./game-start-control');
}

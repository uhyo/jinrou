import './init-icons';
import {
    ThemeStore,
    themeStore,
} from './theme';
export {
    themeStore,
};

export function loadGameStartControl() {
    return import('./game-start-control');
}


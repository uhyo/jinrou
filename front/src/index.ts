import './init-icons';
import {
    ThemeStore,
    themeStore,
} from './theme';
export {
    themeStore,
};

/**
 * Asynchronously load the i18n module.
 */
export function loadI18n() {
    return import('./i18n');
}

/**
 * Asynchronously load the dialog module.
 */
export function loadDialog() {
    return import('./dialog');
}

/**
 * Asynchronously load the game-start-control module.
 */
export function loadGameStartControl() {
    return import('./game-start-control');
}

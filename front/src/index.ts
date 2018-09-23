import '@babel/polyfill';
import '_polyfills';
import './init-icons';
import { ThemeStore, themeStore } from './theme';
export { themeStore };

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
  return import('./pages/game-start-control');
}

/**
 * Asynchronously load the game-view module.
 */
export function loadGameView() {
  return import('./pages/game-view');
}

/**
 * Asynchronoulsly load the user settings module.
 */
export function loadUserSettings() {
  return import('./pages/user-settings');
}

/**
 * Asynchronously load the manual module.
 */
export function loadManual() {
  return import(/* webpackMode: "eager"*/ './manual');
}

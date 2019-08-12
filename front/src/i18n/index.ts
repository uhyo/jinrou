import i18next from 'i18next';
import * as xhrBackend from 'i18next-xhr-backend';

export { I18n, I18nInterp, I18nProvider } from './react';

i18next.use(xhrBackend).init({
  backend: {
    loadPath: '{{lng}}.{{ns}}',
    parse: (data: any) => data,
    ajax,
  },
  interpolation: {
    escapeValue: false,
  },
  fallbackLng: EXTERNAL_SYSTEM_LANGUAGE,
  ns: [
    'common',
    'roles',
    'game_client',
    'game_client_form',
    'rules',
    'casting',
    'server_connection_client',
    'rooms_client',
    'newroom_client',
    'top_client',
    'mypage_client',
  ],
});

/**
 * Reexport type of i18n.
 */
export type i18n = i18next.i18n;
export type TranslationFunction = i18next.TranslationFunction;

/**
 * Preload language data.
 */
export async function preload(lng: string): Promise<void> {
  await getI18nFor(lng);
}

/**
 * Get an instance of i18next for given language.
 */
export function forLanguage(lng: string): i18next.i18n {
  const res = i18next.cloneInstance();
  res.changeLanguage(lng, err => {
    if (err != null) {
      console.error(err);
    }
  });
  return res;
}

/**
 * Get an instance of i18next with specified language loaded.
 */
export function getI18nFor(
  lng: string = EXTERNAL_SYSTEM_LANGUAGE,
): Promise<i18next.i18n> {
  return new Promise((resolve, reject) => {
    const res = i18next.cloneInstance();
    if (lng != null) {
      res.changeLanguage(lng, err => {
        if (err != null) {
          reject(err);
        } else {
          resolve(res);
        }
      });
    } else {
      resolve(res);
    }
  });
}

/**
 * Dynamically load a resource bundle and add to it.
 */
export async function addResource(
  namespace: string,
  target: i18n,
): Promise<void> {
  const lng = target.language;
  if (target.hasResourceBundle(lng, namespace)) {
    // already loaded.
    return;
  }
  // download the bundle.
  const bundle = await loadLanguageBundle(lng, namespace);
  target.addResourceBundle(lng, namespace, bundle);
}

/**
 * Custom resource loading function which makes use of webpack dynamic loading.
 */
async function ajax(
  url: string,
  _options: any,
  callback: (data: any, status: any) => void,
): Promise<void> {
  const [lng, ns] = url.split('.');
  try {
    const data =
      lng === EXTERNAL_SYSTEM_LANGUAGE
        ? await loadSystemLanguageBundle(ns)
        : await loadLanguageBundle(lng, ns);
    callback(data.default, {
      status: '200',
    });
  } catch {
    callback(null, {
      status: '404',
    });
  }
}

/**
 * Dynamically load bundle.
 */
function loadLanguageBundle(
  lng: string,
  ns: string,
): Promise<{ default: unknown }> {
  return import(/*
    webpackChunkName: "language-data-[request]"
  */ `../../../language/${lng}/${ns}.yaml`);
}

/**
 * Dynamically load system language bundle.
 */
function loadSystemLanguageBundle(ns: string): Promise<{ default: unknown }> {
  return import(/*
    webpackPrefetch: true,
    webpackChunkName: "language-data-[request]"
  */ `../../../language/${EXTERNAL_SYSTEM_LANGUAGE}/${ns}.yaml`);
}

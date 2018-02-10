import * as i18next from 'i18next';
import * as xhrBackend from 'i18next-xhr-backend';

export {
    I18n,
} from './react';

i18next
.use(xhrBackend)
.init({
    backend: {
        loadPath: '{{lng}}.{{ns}}',
        parse: (data: any)=> data,
        ajax,
    },
    // TODO language
    fallbackLng: 'ja',
    ns: [
        'roles',
        'game_client',
        'rules',
    ],
});

/**
 * Reexport type of i18n.
 */
export type i18n = i18next.i18n;
export type TranslationFunction = i18next.TranslationFunction;

/**
 * Get an instance of i18next for given language.
 */
export function forLanguage(lng: string): i18next.i18n {
    const res = i18next.cloneInstance();
    res.changeLanguage(lng, (err)=> {
        if (err != null) {
            console.error(err);
        }
    });
    return res;
}

/**
 * Custom resource loading function which makes use of webpack dynamic loading.
 */
async function ajax(url: string, options: any, callback: (data: any, status: any)=>void): Promise<void> {
    const [lng, ns] = url.split('.');
    try {
        const data = await import(`../../../language/${lng}/${ns}.yaml`);
        callback(data.default, {
            status: '200',
        });
    } catch {
        callback(null, {
            status: '404',
        });
    }
}

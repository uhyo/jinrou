declare const EXTERNAL_SYSTEM_LANGUAGE: string;

/**
 * Processing and loading of manual data.
 */

export type HTMLRenderer = (locals?: {}) => string;

/**
 * Load an HTML renderer for one role.
 */
export function loadRoleManual(
  role: string,
  language: string = EXTERNAL_SYSTEM_LANGUAGE,
): Promise<HTMLRenderer> {
  if (language === EXTERNAL_SYSTEM_LANGUAGE) {
    // Special support of system language for smaller load size.
    return import(/*
      webpackMode: "lazy-once",
      webpackChunkName:"manual-syslang-data",
      */
    `../../../manual/${EXTERNAL_SYSTEM_LANGUAGE}/jobs/${role}.jade`).then(
      mod => mod.default,
    );
  } else {
    // Fall back to include-all chunk.
    return import(/*
      webpackMode: "lazy-once",
      webpackChunkName:"manual-all-data",
      */
    `../../../manual/${language}/jobs/${role}.jade`).then(mod => mod.default);
  }
}

declare const EXTERNAL_SYSTEM_LANGUAGE: string;

/**
 * Processing and loading of manual data.
 */

export type HTMLRenderer = (locals?: {}) => string;

/**
 * Load an HTML renderer for one role.
 */
export function loadRoleManual(
  language: string,
  role: string,
): Promise<HTMLRenderer> {
  if (language === EXTERNAL_SYSTEM_LANGUAGE) {
    // Special support of system language for smaller load size.
    return import(/*
      webpackMode: "lazy-once",
      webpackChunkName:"manual-syslang-data",
      */
    `../../../manual/${EXTERNAL_SYSTEM_LANGUAGE}/jobs/${role}.jade`);
  } else {
    // Fall back to include-all chunk.
    return import(/*
      webpackMode: "lazy-once",
      webpackChunkName:"manual-all-data",
      */
    `../../../manual/${language}/jobs/${role}.jade`);
  }
}

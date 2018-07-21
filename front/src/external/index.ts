// This module provides external compile-time resource.
// Resources are provided by DefinePlugin.
// Refer to webpack.config.js for details.

declare const EXTERNAL_SYSTEM_LANGUAGE: string;

/**
 * Default language to be used in front-end application.
 */
export const systemLanguage = EXTERNAL_SYSTEM_LANGUAGE;

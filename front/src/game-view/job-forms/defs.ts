import * as React from 'react';
import { FormDesc } from '../defs';
import { TranslationFunction } from 'i18next';

/**
 * Props to form content renderer.
 */
export interface FormContentProps {
  /**
   * Definition of this form.
   */
  form: FormDesc;
  t: TranslationFunction;
  /**
   * Function to render list of options.
   */
  makeOptions: () => React.ReactNode;
}

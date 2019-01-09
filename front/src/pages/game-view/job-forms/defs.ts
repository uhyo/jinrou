import * as React from 'react';
import { FormDesc } from '../defs';
import { TranslationFunction } from '../../../i18n';

/**
 * Props to form content renderer.
 */
export interface FormContentProps<FormType extends string = string> {
  /**
   * Definition of this form.
   */
  form: FormDesc & { type: FormType };
  t: TranslationFunction;
  /**
   * Function to render list of options.
   */
  makeOptions: () => React.ReactNode;
}

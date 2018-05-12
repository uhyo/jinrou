import * as React from 'react';
import { FormDesc } from '../defs';
import { I18n, TranslationFunction } from '../../i18n';

import { specialNamedTypes, specialContentTypes } from './types';
import { makeGameMasterForm } from './gm';
import { makeMerchantForm } from './merchant';
import { makeWitchForm } from './witch';

export interface IPropJobForms {
  forms: FormDesc[];
}

/**
 * All job forms currently open.
 */
export class JobForms extends React.PureComponent<IPropJobForms, {}> {
  public render() {
    const { forms } = this.props;
    return (
      <div>
        {forms.map((form, i) => <Form key={`${i}-${form.type}`} form={form} />)}
      </div>
    );
  }
}

export interface IPropForm {
  form: FormDesc;
}
/**
 * One job form.
 */
export class Form extends React.PureComponent<IPropForm, {}> {
  public render() {
    const { form } = this.props;
    const { type, options } = form;
    return (
      <I18n namespace="game_client_form">
        {t => {
          // Make name of this form.
          const name = specialNamedTypes.includes(type)
            ? t(`specialName.${type}`)
            : t('game_client_form:normalName', {
                job: t(`jobname.${type}`),
              });

          const content = specialContentTypes.includes(type)
            ? // This is special!
              makeSpecialContent(form, t)
            : makeNormalContent(form);

          return (
            <form>
              <fieldset>
                <legend>{name}</legend>
                {content}
              </fieldset>
            </form>
          );
        }}
      </I18n>
    );
  }
}

/**
 * Make a normal content for job form.
 */
function makeNormalContent({ options }: FormDesc) {
  // List up options.
  const opts = options.map(({ name, value }, i) => (
    <label>
      {name}
      <input key={`${i}-${value}`} type="range" name="target" value={value} />
    </label>
  ));
  return <p>{opts}</p>;
}

/**
 * Make special content of job form.
 */
function makeSpecialContent(form: FormDesc, t: TranslationFunction) {
  switch (form.type) {
    case 'GameMaster': {
      return makeGameMasterForm(form, t);
    }
    case 'Merchant': {
      return makeMerchantForm(form, t);
    }
    case 'Witch': {
      return makeWitchForm(form, t);
    }
    default: {
      console.error(`Special form for ${form.type} is undefined`);
      return null;
    }
  }
}

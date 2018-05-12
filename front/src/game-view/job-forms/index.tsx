import * as React from 'react';
import { FormDesc } from '../defs';
import { I18n, TranslationFunction } from '../../i18n';

import { specialNamedTypes, specialContentTypes } from './types';
import { makeGameMasterForm } from './gm';
import { makeMerchantForm } from './merchant';
import { makeWitchForm } from './witch';

export interface IPropJobForms {
  forms: FormDesc[];
  onSubmit: (query: Record<string, string>) => void;
}

/**
 * All job forms currently open.
 */
export class JobForms extends React.PureComponent<IPropJobForms, {}> {
  public render() {
    const { forms, onSubmit } = this.props;
    return (
      <div>
        {forms.map((form, i) => (
          <Form key={`${i}-${form.type}`} form={form} onSubmit={onSubmit} />
        ))}
      </div>
    );
  }
}

export interface IPropForm {
  form: FormDesc;
  onSubmit: (query: Record<string, string>) => void;
}
/**
 * One job form.
 */
export class Form extends React.PureComponent<IPropForm, {}> {
  public render() {
    const { form, onSubmit } = this.props;
    const { type, options } = form;
    return (
      <I18n namespace="game_client_form">
        {t => {
          // Make name of this form.
          const name = specialNamedTypes.includes(type)
            ? t(`specialName.${type}`)
            : t('normalName', {
                job: t(`roles:jobname.${type}`),
              });

          const content = specialContentTypes.includes(type)
            ? // This is special!
              makeSpecialContent(form, t)
            : makeNormalContent(form, t);

          // Handle submission of job form.
          const handleSubmit = (e: React.SyntheticEvent<HTMLFormElement>) => {
            e.preventDefault();
            const form = e.currentTarget;
            // Retrieve a key/value pairs of the form.
            const data = new FormData(form);
            // Make a plain object from it.
            const query: Record<string, string> = {};
            for (const [key, value] of data.entries()) {
              // value is either string or File.
              // File should not occur here.
              if ('string' === typeof value) {
                query[key] = value;
              } else {
                console.warn('File', value);
              }
            }
            // query is generated
            console.log(query);
            onSubmit(query);
          };

          return (
            <form onSubmit={handleSubmit}>
              <fieldset>
                <legend>{name}</legend>
                {content}
                <p>
                  <input
                    type="submit"
                    value={t('game_client_form:normalButton')}
                  />
                </p>
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
function makeNormalContent(
  { type, options }: FormDesc,
  t: TranslationFunction,
) {
  // List up options.
  const opts = options.map(({ name, value }, i) => (
    <label>
      {name}
      <input key={`${i}-${value}`} type="range" name="target" value={value} />
    </label>
  ));
  return (
    <>
      <p>{t(`game_client_form:messages.${type}`)}</p>
      <p>{opts}</p>
    </>
  );
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

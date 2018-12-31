import * as React from 'react';
import { FormDesc } from '../defs';
import { I18n, TranslationFunction } from '../../../i18n';

import { specialNamedTypes, specialContentTypes } from './types';
import { makeGameMasterForm } from './gm';
import { makeMerchantForm } from './merchant';
import { makeWitchForm } from './witch';
import {
  OptionLabel,
  FormWrapper,
  JobFormsWrapper,
  FormName,
  FormContent,
  SelectWrapper,
  FormStatusLine,
  FormTypeWrapper,
} from './elements';
import { FormContentProps } from './defs';
import { makeWerewolfForm } from './werewolf';

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
      <JobFormsWrapper>
        {forms.map((form, i) => (
          <Form key={`${i}-${form.type}`} form={form} onSubmit={onSubmit} />
        ))}
      </JobFormsWrapper>
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
  /**
   * Saved name of submit button.
   */
  protected commandName: string = '';
  public render() {
    const { form, onSubmit } = this.props;
    const { type, options, formType, objid } = form;
    return (
      <I18n namespace="game_client_form">
        {t => {
          // Make name of this form.
          const name = specialNamedTypes.includes(type)
            ? t(`specialName.${type}`)
            : t('normalName', {
                job: t(`roles:jobname.${type}`),
              });
          const formTypeStr = t(`formType.${formType}`);
          // Make options as renderer.
          const makeOptions = () =>
            options.map(({ name, value }, i) => (
              <OptionLabel key={`${i}-value`}>
                {name}
                <input type="radio" name="target" value={value} />
              </OptionLabel>
            ));

          const content = specialContentTypes.includes(type)
            ? // This is special!
              makeSpecialContent({ form, t, makeOptions })
            : makeNormalContent({ form, t, makeOptions });

          // Handle submission of job form.
          const handleSubmit = (e: React.SyntheticEvent<HTMLFormElement>) => {
            e.preventDefault();
            const form = e.currentTarget;
            // Make a plain object from it.
            const query: Record<string, string> = {};
            /*
            // this nice code does not work for Edge now...
            // Retrieve a key/value pairs of the form.
            const data = new FormData(form);
            for (const [key, value] of data.entries()) {
              // value is either string or File.
              // File should not occur here.
              if ('string' === typeof value) {
                query[key] = value;
              } else {
                console.warn('File', value);
              }
            }
            */
            for (const elm of Array.from(form.elements)) {
              const e = elm as any;
              if (e.name != null) {
                if (e.type === 'radio' && !e.checked) {
                  continue;
                }
                query[e.name] = e.value;
              }
            }
            // add special parameters
            if (this.commandName !== '') {
              query.commandname = this.commandName;
            }
            query.jobtype = type;
            query.objid = objid;
            // query is generated
            console.log(query);
            onSubmit(query);
          };
          // Handle click of something.
          const handleClick = (e: React.SyntheticEvent<HTMLFormElement>) => {
            const t = e.target as HTMLInputElement;
            // When submit button is clicked, save its name,
            if (t.tagName === 'INPUT' && t.type === 'submit') {
              this.commandName = t.name;
            }
          };

          return (
            <FormWrapper>
              <form onSubmit={handleSubmit} onClick={handleClick}>
                <FormStatusLine>
                  <FormName>{name}</FormName>
                  <FormTypeWrapper formType={formType}>
                    {formTypeStr}
                  </FormTypeWrapper>
                </FormStatusLine>
                <FormContent>
                  {content}
                  <SelectWrapper>
                    <input
                      type="submit"
                      value={t('game_client_form:normalButton')}
                    />
                  </SelectWrapper>
                </FormContent>
              </form>
            </FormWrapper>
          );
        }}
      </I18n>
    );
  }
}

/**
 * Make a normal content for job form.
 */
function makeNormalContent({
  form: { type },
  t,
  makeOptions,
}: FormContentProps) {
  return (
    <>
      <p>{t(`game_client_form:messages.${type}`)}</p>
      <p>{makeOptions()}</p>
    </>
  );
}

/**
 * Make special content of job form.
 */
function makeSpecialContent(props: FormContentProps) {
  const { form, makeOptions } = props;
  let otherContents;
  switch (form.type) {
    case 'GameMaster': {
      otherContents = makeGameMasterForm(props);
      break;
    }
    case 'Merchant':
    case 'HomeComer': {
      otherContents = makeMerchantForm(props, form.type);
      break;
    }
    case 'Witch': {
      otherContents = makeWitchForm(props);
      break;
    }
    case '_Werewolf': {
      otherContents = makeWerewolfForm(props as FormContentProps<'_Werewolf'>);
      break;
    }
    default: {
      console.error(`Special form for ${form.type} is undefined`);
      return null;
    }
  }
  return (
    <>
      {otherContents}
      {makeOptions()}
    </>
  );
}

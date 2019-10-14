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
import { useI18n } from '../../../i18n/react';
import { makeDragonKnightForm } from './dragonKnight';
import { makePoet1Form, makePoet2Form } from './poet';
import {
  makeGachaAddictedNormalForm,
  makeGachaAddictedPremiumForm,
  makeGachaAddictedCommitForm,
} from './gachaAddicted';

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
export const Form: React.FC<IPropForm> = React.memo(({ form, onSubmit }) => {
  /**
   * Saved name of submit button.
   */
  const commandNameRef = React.useRef('');
  const { type, options, formType, objid } = form;

  const t = useI18n('game_client_form');

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
        <bdi>{name}</bdi>
        <input type="radio" name="target" value={value} />
      </OptionLabel>
    ));

  const { content, buttons } = makeFormContent({ form, t, makeOptions });

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
    if (commandNameRef.current !== '') {
      query.commandname = commandNameRef.current;
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
      commandNameRef.current = t.name;
    }
  };

  return (
    <FormWrapper>
      <form onSubmit={handleSubmit} onClick={handleClick}>
        <FormStatusLine>
          <FormName>{name}</FormName>
          <FormTypeWrapper formType={formType}>{formTypeStr}</FormTypeWrapper>
        </FormStatusLine>
        <FormContent>
          {content}
          <SelectWrapper>{buttons}</SelectWrapper>
        </FormContent>
      </form>
    </FormWrapper>
  );
});

interface FormContent {
  /**
   * main content of one form.
   */
  content: React.ReactNode;
  /**
   * submit buttons.
   */
  buttons: React.ReactNode;
}
/**
 * Make contents of one form.
 */
function makeFormContent(props: FormContentProps): FormContent {
  const {
    content = makeNormalContent(props),
    buttons = makeNormalButtons(props),
  } = specialContentTypes.includes(props.form.type)
    ? makeSpecialContent(props)
    : {};
  return {
    content,
    buttons,
  };
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
function makeNormalButtons({ t }: FormContentProps) {
  return <input type="submit" value={t('game_client_form:normalButton')} />;
}

/**
 * Make special content of job form.
 */
function makeSpecialContent(props: FormContentProps): Partial<FormContent> {
  const { form, makeOptions } = props;
  let otherContents;
  let buttons;
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
    case 'DragonKnight': {
      ({ content: otherContents, buttons } = makeDragonKnightForm(
        props as FormContentProps<'DragonKnight'>,
      ));
      break;
    }
    case 'Poet1': {
      otherContents = makePoet1Form(props as FormContentProps<'Poet1'>);
      break;
    }
    case 'Poet2': {
      otherContents = makePoet2Form(props as FormContentProps<'Poet2'>);
      break;
    }
    case 'GachaAddicted_Normal': {
      ({ content: otherContents, buttons } = makeGachaAddictedNormalForm(
        props as FormContentProps<'GachaAddicted_Normal'>,
      ));
      break;
    }
    case 'GachaAddicted_Premium': {
      ({ content: otherContents, buttons } = makeGachaAddictedPremiumForm(
        props as FormContentProps<'GachaAddicted_Premium'>,
      ));
      break;
    }
    case 'GachaAddicted_Commit': {
      ({ content: otherContents, buttons } = makeGachaAddictedCommitForm(
        props as FormContentProps<'GachaAddicted_Commit'>,
      ));
      break;
    }
    default: {
      console.error(`Special form for ${form.type} is undefined`);
      return {};
    }
  }
  return {
    content: (
      <>
        {otherContents}
        {makeOptions()}
      </>
    ),
    buttons,
  };
}

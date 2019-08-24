import { useUniqueId } from '../../../util/useUniqueId';
import React from 'react';
import { FontAwesomeIcon } from '../../../util/icon';
import {
  Input,
  InputLabel,
  InputContent,
  EditableInputs,
  InputHelpIcon,
} from './elements';

export { EditableInputs };

interface Props {
  label: string;
  helpText?: string;
  onChange?: (value: string) => void;
  additionalText?: string;
  defaultValue: string;
  readOnly?: boolean;
  required?: boolean;
  type?: string;
  maxLength?: number;
  autoComplete?: string;
}

export const EditableInput: React.FunctionComponent<Props> = ({
  label,
  helpText,
  defaultValue,
  onChange,
  additionalText,
  ...inputProps
}) => {
  const inputId = useUniqueId();

  return (
    <EditableInputWrapper labelFor={inputId} label={label} helpText={helpText}>
      <Input
        id={inputId}
        defaultValue={defaultValue}
        onChange={e => onChange != null && onChange(e.currentTarget.value)}
        {...inputProps}
      />
      {additionalText}
    </EditableInputWrapper>
  );
};

export const EditableInputWrapper: React.FunctionComponent<{
  labelFor?: string;
  helpText?: string;
  label: string;
}> = ({ labelFor, label, helpText, children }) => (
  <>
    <InputLabel htmlFor={labelFor}>{label}</InputLabel>
    <InputHelpIcon>
      {helpText ? (
        <FontAwesomeIcon
          size="sm"
          data-helpicon
          icon={['far', 'question-circle']}
          data-title={helpText}
        />
      ) : null}
    </InputHelpIcon>
    <InputContent>{children}</InputContent>
  </>
);

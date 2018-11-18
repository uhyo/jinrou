import { ActiveButton, Button } from './button';
import { FontAwesomeIcon } from '../../../util/icon';
import * as React from 'react';
import { withProps } from 'recompose';
import { arrayMapToObject } from '../../../util/array-map-to-object';

export interface IPropRadioButtons {
  current: string;
  options: Array<{
    label: string;
    value: string;
  }>;
  onChange: (value: string) => void;
}

type IPropRadioButtonsInner = Pick<IPropRadioButtons, 'current' | 'options'> & {
  onChange: Record<string, () => void>;
};

const addProps = withProps(({ options, onChange }: IPropRadioButtons) => ({
  onChange: arrayMapToObject<string, Record<string, () => void>>(
    options.map(obj => obj.value),
    value => () => onChange(value),
  ),
}));
/**
 * Radio button using buttons.
 */
export const RadioButtonsInner = ({
  current,
  options,
  onChange,
}: IPropRadioButtonsInner) => {
  return (
    <>
      {options.map(
        ({ label, value }) =>
          value === current ? (
            <ActiveButton key={value}>
              <FontAwesomeIcon icon="check" />
              {label}
            </ActiveButton>
          ) : (
            <Button key={value} onClick={onChange[value]}>
              {label}
            </Button>
          ),
      )}
    </>
  );
};

export const RadioButtons = addProps(RadioButtonsInner);

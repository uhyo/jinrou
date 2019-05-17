import { ActiveButton, Button } from './button';
import { FontAwesomeIcon } from '../../util/icon';
import * as React from 'react';
import { withProps } from 'recompose';
import { arrayMapToObject } from '../../util/array-map-to-object';
import styled from '../../util/styled';
import { contentMargin } from './style';

export interface IPropRadioButtons {
  current: string;
  options: Array<{
    label: string;
    value: string;
    /**
     * Optinal string description shown on hover.
     */
    title?: string;
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
    <RadioButtonWrapper role="radiogroup">
      {options.map(({ label, value, title }) => {
        const checked = value === current;
        return (
          <ActiveButton
            type="button"
            key={value}
            title={title}
            role="radio"
            aria-checked={checked}
            active={checked}
            onClick={onChange[value]}
          >
            {checked ? <FontAwesomeIcon icon="check" /> : null}
            {label}
          </ActiveButton>
        );
      })}
    </RadioButtonWrapper>
  );
};

const RadioButtonWrapper = styled.span`
  display: inline-block;
  margin: ${-contentMargin}px 0;
`;

export const RadioButtons = addProps(RadioButtonsInner);

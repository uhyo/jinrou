import * as React from 'react';
import { ActiveButton, Button, IPropButton } from './button';
import { FontAwesomeIcon } from '../../util/icon';

/**
 * Button which is a checkbox.
 */
export const CheckButton: React.FC<
  {
    checked: boolean;
    onChange(value: boolean): void;
  } & IPropButton
> = ({ checked, onChange, children, slim }) => (
  <ActiveButton
    onClick={() => onChange(!checked)}
    role="checkbox"
    aria-checked={checked}
    active={checked}
    slim={slim}
  >
    {checked ? <FontAwesomeIcon icon="check" /> : null}
    {children}
  </ActiveButton>
);

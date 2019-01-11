import styled from '../../../util/styled';
import { phone, notPhone } from '../../../common/media';
import * as React from 'react';

/**
 * Form for styling.
 * @package
 */
export const MainForm = styled.form`
  line-height: 1;
  ${phone`
    display: grid;
    grid-template: "button  input    speakbutton"
                   "button  controls controls"
                   "others  others   others"
                   / 5ex 1fr 64px;
    gap: 4px;
  `};
  ${notPhone`
    display: flex;
    flex-flow: row wrap;
    align-items: flex-end;
  `};
`;

/**
 * Area for speak input.
 * @package
 */
export const SpeakInputArea = styled.span`
  ${phone`
    grid-area: input;
  `};
`;

/**
 * Area for speak button.
 * @package
 */
export const SpeakButtonArea = styled.span`
  ${phone`
    grid-area: speakbutton;
  `};
`;

/**
 * Area for input controls.
 * @package
 */
export const SpeakControlsArea = styled.span`
  ${phone`
    grid-area: controls;
    display: flex;
    flex-flow: row wrap;
    align-items: flex-end;
  `};
  ${notPhone`
    display: contents;
  `};
`;

/**
 * Area for others.
 * @package
 */
export const OthersArea = styled.span`
  ${phone`
    grid-area: others;
    &:not([hidden]) {
      display: flex;
      flex-flow: row wrap;
      align-items: flex-end;
    }
  `};
  ${notPhone`
    display: contents;
  `};
`;

/**
 * Area for expand button.
 */
export const ButtonArea = styled.span`
  ${phone`
    grid-area: button;
  `};
`;

/**
 * Main input of form.
 * @package
 */
export const SpeakInput = styled.input`
  box-sizing: border-box;
  max-width: 100%;
  ${phone`
    width: 100%;
  `};
`;

/**
 * Multiline mode form.
 * @package
 */
export const SpeakTextArea = styled.textarea`
  box-sizing: border-box;
  max-width: 100%;
  ${phone`
    width: 100%;
  `};
`;

/**
 * Labelled container of one form control.
 * @package
 */
export const LabeledControl = styled(({ children, className, label }) => {
  return (
    <label className={className}>
      <span>{label}</span>
      <span>{children}</span>
    </label>
  );
})<{
  className?: string;
  label: string;
}>`
  display: inline-flex;
  flex-flow: column nowrap;

  span:first-of-type {
    font-size: xx-small;
    margin-bottom: 2px;
    opacity: 0.75;
  }

  ${notPhone`
    margin: 0 2px;
  `};
`;

export const SpeakControlsSlim = styled.span`
  font-size: xx-small;
  opacity: 0.75;
`;

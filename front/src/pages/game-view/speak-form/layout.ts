import styled from '../../../util/styled';
import { phone } from '../../../common/media';

/**
 * Form for styling.
 * @package
 */
export const MainForm = styled.form`
  ${phone`
    display: grid;
    grid-template: "button  input    speakbutton"
                   "button  controls controls"
                   "others  others   others"
                   / 5ex 1fr 64px;
    gap: 4px;
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
  `};
`;

/**
 * Area for others.
 * @package
 */
export const OthersArea = styled.span`
  ${phone`
    grid-area: others;
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

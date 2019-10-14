import styled from 'styled-components';
import { FormType } from '../defs';
import { phone } from '../../../common/media';
import { formLinkColor } from '../../../common/color';

/**
 * Wrapper of all forms.
 */
export const JobFormsWrapper = styled.div`
  display: flex;
  flex-flow: row wrap;

  ${phone`
    flex-flow: column nowrap;
  `};
`;
/**
 * Wrapper of form.
 */
export const FormWrapper = styled.div`
  margin: 4px;
  background-color: rgba(255, 255, 255, 0.9);
  color: #000000;
  font-size: var(--base-font-size);

  p {
    margin: 4px 0;
  }

  a {
    color: ${formLinkColor};
  }
`;

/**
 * Wrapper of form top line.
 */
export const FormStatusLine = styled.div`
  display: flex;
  flex-flow: row wrap;
  form-size: smaller;
`;

/**
 * Wrapper of form name.
 */
export const FormName = styled.div`
  flex: auto 0 0;
  padding: 3px 5px;
  background-color: #dddddd;
`;
/**
 * Wrapper of form type.
 */
export const FormTypeWrapper = styled.div<{ formType: FormType }>`
  flex: auto 0 0;
  padding: 3px 5px;
  color: ${({ formType }) => (formType === 'required' ? '#ff0000' : '#555555')};
`;
/**
 * Wrapper of form main content.
 */
export const FormContent = styled.div`
  margin: 0;
  padding: 5px;
`;

/**
 * Wrapper of select button.
 */
export const SelectWrapper = styled.div`
  text-align: center;
`;

/**
 * Label for each option.
 */
export const OptionLabel = styled.label`
  display: inline-block;
  margin-left: 0.8em;

  :hover {
    background-color: #eeeebb;
    box-shadow: 0 0 4px 4px #eeeebb;
  }

  ${phone`
    margin: 0.6em;
  `};
`;

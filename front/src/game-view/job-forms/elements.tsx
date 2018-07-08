import styled from 'styled-components';

/**
 * Wrapper of all forms.
 */
export const JobFormsWrapper = styled.div`
  display: flex;
  flex-flow: row wrap;
`;
/**
 * Wrapper of form.
 */
export const FormWrapper = styled.div`
  margin: 4px;
  background-color: #f4f4f4;
  color: #000000;

  p {
    margin: 4px 0;
  }
`;

/**
 * Wrapper of form name.
 */
export const FormName = styled.div`
  width: fit-content;
  margin: 0 auto 0 0;
  padding: 3px 5px;
  background-color: #dddddd;
  font-size: smaller;
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
`;

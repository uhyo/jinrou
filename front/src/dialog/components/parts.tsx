import styled from 'styled-components';

const ButtonBase = styled.button`
  appearance: none;

  border: none;
  margin: 6px;
  padding: 0.3em 1em;
  text-align: center;

  font-size: 1.24em;
  font-weight: bold;
`;
/**
 * Button with affirmative impression.
 */
export const YesButton = styled(ButtonBase)`
  background-color: #83f183;
`;
/**
 * Button with negative impression.
 */
export const NoButton = styled(ButtonBase)`
  background-color: #dddddd;
`;

/**
 * Table for use in dialog.
 */
export const FormTable = styled.table`
  margin: 5px auto;

  th,
  td {
    border: none;
    vertical-align: middle;
  }
`;

/**
 * Wrapper of simple form component in form.
 */
export const FormControlWrapper = styled.div`
  margin: 5px auto;
  text-align: center;
`;

/**
 * Wrapper of aside text in a dialog.
 */
export const FormAsideText = styled.div`
  margin: 5px 0;

  text-align: right;
  font-size: 0.9em;
`;

/**
 * Wrapper of error message in a dialog.
 */
export const FormErrorMessage = styled.div`
  margin: 5px 0;

  color: red;
  font-size: 0.9em;
`;
/**
 * Input for form in dialog.
 */
export const FormInput = styled.input`
  background-color: white;
  width: 240px;
  padding: 0.4em;
  border: 1px solid #cccccc;

  &:focus {
    border-color: #83f183;
    outline-color: #83f183;
  }
  &:disabled {
    background-color: #eeeeee;
    color: #888888;
  }
`;

/**
 * Select for form in dialog.
 */
export const FormSelect = styled.select`
  background-color: white;
  width: 240px;
  padding: 0.4em;
  border: 1px solid #cccccc;

  &:focus {
    border-color: #83f183;
    outline-color: #83f183;
  }
  &:disabled {
    background-color: #eeeeee;
    color: #888888;
  }
`;

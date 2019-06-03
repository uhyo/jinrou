import styled from '../../util/styled';
import { AppStyling } from '../../styles/phone';
import { mediumBorderColor } from '../../common/color';

export const AppWrapper = styled(AppStyling)``;

/**
 * Wrapper of forms
 * @internal
 */
export const FormWrapper = styled.div`
  width: max-content;
  max-width: 100%;
  margin: 0.5em auto 0.5em 0;
  padding: 0.3em 1em;
  border: 1px solid ${mediumBorderColor};

  h2 {
    margin-top: 0;
  }
`;

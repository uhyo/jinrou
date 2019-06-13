import styled from '../../util/styled';
import { formComponentsVerticalMergin } from '../style';

/**
 * @package
 */
export const FormWrapper = styled.div`
  margin: ${formComponentsVerticalMergin} 0;
  display: grid;

  grid-template:
    'namelabel nameinput' 1fr
    'passlabel passinput' 1fr / max-content max-content;
  gap: 2px;
  justify-content: center;
`;

/**
 * @package
 */
export const Label = styled.label`
  font-weight: bold;
`;

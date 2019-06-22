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
  display: flex;
  flex-flow: column nowrap;
  justify-content: center;
`;

/**
 * @package
 */
export const LabelInner = styled.span`
  font-weight: bold;
`;

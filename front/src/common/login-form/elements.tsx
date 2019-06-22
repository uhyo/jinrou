import styled from '../../util/styled';
import { formComponentsVerticalMergin } from '../style';
import { phone } from '../media';

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

  ${phone`
    grid-template:
      'namelabel' auto
      'nameinput' 1fr
      'passlabel' auto
      'passinput' 1fr / max-content;
  `};
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

import { FormContentProps } from './defs';
import { getFormData } from '../defs';
import * as React from 'react';
import styled from '../../../util/styled';

/**
 * Make a Poet1 (initial Poet) form.
 */
export function makePoet1Form({ form, t }: FormContentProps<'Poet1'>) {
  const data = getFormData(form);

  const content = (
    <>
      <p>{t('game_client_form:Poet.descriptionInit')}</p>
      <PoemTextArea placeholder={t('game_client_form:Poet.poemPlaceholder')} />
    </>
  );

  return content;
}

const PoemTextAreaWrapper = styled.div`
  width: 100%;
  max-width: 20em;
  margin: 0.8em 0;

  textarea {
    width: 100%;
  }
`;
/**
 * Textarea to input poem.
 */
const PoemTextArea: React.FunctionComponent<{
  placeholder?: string;
}> = ({ placeholder }) => {
  return (
    <PoemTextAreaWrapper>
      <textarea placeholder={placeholder} />
    </PoemTextAreaWrapper>
  );
};

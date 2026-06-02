import { ProcessStepModel } from './ProcessStepModel';

export class ProcessModel {
  id: number = 0;
  code: string = '';
  name: string = '';
  applicableProductCodes: string = '';
  steps: ProcessStepModel[] = [];
}

import 'package:flutter/material.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';

Future<dynamic> termsOfUse({
  required BuildContext context,
  required void Function()? onPressedIsTerm,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Termo de Uso'),
            IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(
                  Icons.close,
                  color: Colors.black54,
                ))
          ],
        ),
        content: const Text(
          'Momento Fiscal',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 350,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACORDO ENTRE O USUÁRIO E MARCO ZERO COMUNICAÇÃO E FILMAGENS',
                          style: textTitleTermOfUse,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          '1. Disposições Gerais',
                          textAlign: TextAlign.start,
                          style: textTitleTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "  Seja bem-vindo à plataforma do MOMENTO FISCAL , inscrita sobre o CNPJ nº 12.477.240/0001-60. O MARCO ZERO COMUNICAÇÃO E FILMAGENS , assume seriamente suas responsabilidades sob as leis e regulamentos de privacidade aplicáveis​​(\"Leis de Privacidade\") e está comprometido em respeitar os direitos e preocupações de privacidade de todos os Usuários do website e aplicativo para celular do MOMENTO FISCAL (a \"Plataforma\").",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  O termo “Usuários” se refere ao usuário que registrou uma conta com o MOMENTO FISCAL para utilização dos serviços.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  Reconhecemos a importância dos dados pessoais que você nos confiou e acreditamos que é nossa responsabilidade gerenciar, proteger e processar adequadamente seus dados pessoais. Esta Política de Privacidade (\"Política de Privacidade\" ou \"Política\") foi criada para ajudá-lo a entender como coletamos, usamos, divulgamos e / ou processamos os dados pessoais que você nos forneceu e/ou possuímos sobre você, agora ou no futuro, além de ajudá-lo a tomar uma decisão informada antes de nos fornecer seus dados pessoais.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  1.3 Ao usar os Serviços, registrar uma conta conosco, visitar nossa Plataforma ou acessar os Serviços, você reconhece e concorda que aceita as práticas, requisitos e/ou políticas descritas nesta Política de Privacidade e, por meio deste, concorda em que coletemos e usemos exclusivamente para os fins específicos que o serviço requeira, seus dados pessoais, conforme descrito aqui. SE VOCÊ NÃO CONSENTIR COM O PROCESSAMENTO DE SEUS DADOS PESSOAIS, CONFORME DESCRITO NESTA POLÍTICA DE PRIVACIDADE, POR FAVOR, NÃO USE NOSSOS SERVIÇOS NEM ACESSE NOSSA PLATAFORMA. Se alterarmos nossa Política de Privacidade, vamos notificar você através da publicação dessas alterações ou a Política de Privacidade alterada em nossa Plataforma. Reservamo-nos o direito de alterar esta Política de Privacidade a qualquer momento. Até o limite máximo permitido pela legislação aplicável, o ato de continuar utilizando os Serviços ou Plataforma, incluindo a realização de pedidos de compras, será considerado o seu reconhecimento e concordância com as alterações implementadas na presente Política de Privacidade.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  1.4 A presente Política de Privacidade será aplicada conjuntamente com outros regulamentos, notificações, cláusulas contratuais, cláusulas de consentimento aplicáveis a coleta, armazenamento e/ou processamento dos seus dados pessoais pelo MOMENTO FISCAL e não se sobrepõe as referidas notificações, regulamentos ou cláusulas a menos que expressamente disposto pelo MOMENTO FISCAL neste sentido.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  1.5 Essa Política de Privacidade se aplica a todos os usuários da Plataforma e serviços prestados pelo MOMENTO FISCAL, incluindo Gestores, Vendedores, exceto se expressamente disposto pelo MOMENTO FISCAL de outra forma.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "2. QUANDO O MOMENTO FISCAL RECOLHERÁ DADOS PESSOAIS?",
                          style: textTitleTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "  2.1 Nós iremos / poderemos coletar dados pessoais sobre você:",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Quando você se registra e/ou usa nossos Serviços ou Plataforma, ou abre uma conta conosco.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Quando você envia qualquer formulário, incluindo, entre outros, formulários de inscrição ou outros formulários relacionados a qualquer um de nossos produtos e serviços, seja online ou por meio de um formulário físico;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Quando você firma qualquer contrato ou fornece outra documentação ou informação a respeito de suas interações conosco ou quando você usa nossos produtos e serviços;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Quando você interage conosco, como em chamadas telefônicas (que podem ser gravadas), cartas, fax, reuniões presenciais, plataformas de mídia social e e-mails, incluindo quando você interage ativamente com os nossos serviços de suporte e atendimento ao cliente;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Quando você usa nossos serviços eletrônicos, ou interage conosco por meio de nosso aplicativo ou usa serviços em nossa Plataforma. Isso inclui, sem limitação, através de cookies que podemos implantar quando você interage com nosso aplicativo ou site;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Quando você concede permissão no seu dispositivo para compartilhar informações com os nossos aplicativos ou Plataforma;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Quando você realiza transações através de nossos Serviços;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Quando você nos fornece feedback ou reclamações;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Quando você se inscreve em um concurso; ou",
                          style: textTermOfUse,
                        ),
                        Text(
                          "  • Quando você envia seus dados pessoais para nós por qualquer motivo.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "O acima exposto não pretende ser exaustivo e define alguns exemplos comuns de quando podem ser coletados dados pessoais sobre você.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "QUE DADOS PESSOAIS O MOMENTO FISCAL VAI COLETAR?",
                          style: textTitleTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "3.1 ​Os dados pessoais que o MOMENTO FISCAL pode coletar incluem, entre outros:",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text("  • Nome;"),
                        SizedBox(height: 6),
                        Text(
                          "  • Endereço de e-mail;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text("  • Data de nascimento;"),
                        SizedBox(height: 6),
                        Text(
                          "  • Endereço de cobrança ou de entrega;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Conta bancária e informações de pagamento;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Número de telefone;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Sexo;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Informações enviadas ou associadas ao(s) dispositivo(s) usado(s) para acessar nossos Serviços ou Plataforma;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Informações sobre a sua rede de internet, bem como as pessoais e contas com as quais você tenha interagido;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Gravações e arquivos de fotos, áudios ou vídeos;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Documentos de identificação emitidos pelas autoridades públicas competentes e/ou outras informações requeridas em razão de nossas auditorias, processo de conheça o seu cliente, verificação e validação de identidade de usuários, bem como para processos de prevenção a fraude e combate à lavagem de dinheiro;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Dados de publicidade e comunicações, como as suas preferências relativas ao recebimento de publicidade nossa ou de terceiros, suas preferências de comunicação, histórico de comunicação conosco, nossos prestadores de serviço e outros terceiros;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Dados de utilização dos serviços e transacionais, incluindo detalhes sobre as suas buscas, pedidos, propaganda e conteúdo com o qual você interage na Plataforma e outros produtos e serviços relacionados a vocês;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Dados de localização e geolocalização;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Quaisquer outras informações sobre o usuário quando o usuário se inscrever para usar nossos Serviços ou Plataforma e quando o usuário usar os Serviços ou Plataforma, bem como informações relacionadas a como o usuário usa nossos Serviços ou Plataforma; e",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Dados agregados sobre o conteúdo com o qual o Usuário se envolve.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Dados relativos ao seu estado de saúde, tipos de doenças que possui, e à sua rotina de vida como alimentação, horário de remédios, tipos de remédios que utiliza, contatos de médicos, planos de saúde contratados",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "  3.2 Você concorda em não nos enviar nenhuma informação imprecisa ou enganosa, e concorda em nos informar sobre quaisquer imprecisões ou alterações nessas informações. Reservamo-nos o direito de, a nosso exclusivo critério, exigir documentação adicional para verificar as informações fornecidas por você.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  3.3 Se você se inscrever como usuário de nossa Plataforma usando sua conta de mídia social (\"Conta de mídia social\"), vincular sua conta do MOMENTO FISCAL à sua conta de mídia social ou usar qualquer recurso de mídia social do MOMENTO FISCAL, poderemos acessar informações sobre você que você tenha fornecido voluntariamente ao provedor da sua conta de mídia social, de acordo com as políticas desse provedor, e gerenciaremos e usaremos esses dados pessoais de acordo com esta Política o tempo todo.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  3.4 Se você não deseja que coletemos as informações / dados pessoais acima mencionados, você pode optar por não participar a qualquer momento, notificando por escrito nosso Diretor de Proteção de Dados. Mais informações sobre a desativação podem ser encontradas na seção abaixo, intitulada \"Como você pode retirar o consentimento, remover, solicitar acesso ou modificar as informações que você nos forneceu?\". Observe, no entanto, que a exclusão ou retirada do seu consentimento para coletar, usar ou processar seus dados pessoais pode afetar o uso dos Serviços e da Plataforma. Por exemplo, desativar a coleta de informações de localização fará com que seus recursos baseados em localização sejam desativados.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "4. COLETA DE OUTROS DADOS",
                          style: textTitleTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "  4.1 Como na maioria dos sites e aplicativos móveis, seu dispositivo envia informações que podem incluir dados sobre você que são registrados por um servidor da web quando você navega em nossa Plataforma. Isso geralmente inclui, sem limitação, o endereço IP do dispositivo, o sistema operacional do computador / dispositivo móvel e o tipo de navegador, tipo de dispositivo móvel, as características do dispositivo móvel, o identificador exclusivo de dispositivo (UDID) ou o identificador de equipamento móvel (MEID) do seu dispositivo móvel, o endereço de um site de referência (se houver), as páginas que você visita em nosso site e aplicativos para dispositivos móveis e os horários da visita e, às vezes, um \"cookie\" (que pode ser desativado usando as preferências do navegador) para ajudar o site a lembrar sua última visita. Se iniciou sessão, essas informações serão associadas à sua conta pessoal. A informação também está incluída nas estatísticas anônimas para nos permitir entender como os visitantes usam nosso site.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  4.2 Nossos aplicativos móveis podem coletar informações precisas sobre a localização do seu dispositivo móvel usando tecnologias como GPS, Wi-Fi etc. Coletamos, usamos, divulgamos e / ou processamos essas informações para uma ou mais finalidades, incluindo, sem limitação, os serviços baseados em localização solicitados ou para fornecer conteúdo relevante a você com base em sua localização ou para permitir que você compartilhe sua localização com outros Usuários como parte dos serviços em nossos aplicativos móveis. Para a maioria dos dispositivos móveis, você pode retirar sua permissão para obtermos essa informação sobre sua localização através das configurações do dispositivo. Se você tiver dúvidas sobre como desativar os serviços de localização do seu dispositivo móvel, entre em contato com o provedor de serviços do dispositivo móvel ou o fabricante do dispositivo.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  4.3 Quando você visualiza páginas em nosso site ou aplicativo móvel, bem como quando você assiste a conteúdo e anúncios, publicidade e acessa algum software em nossa Plataforma ou através do uso dos nossos Serviços, a maioria das mesmas informações citadas acima são enviadas para o MARCO ZERO COMUNICAÇÃO E FILMAGENS (incluindo, sem limitação, endereço IP, sistema operacional , etc.); porém, em vez de visualizações de página, seudispositivo nos enviará informações sobre o conteúdo, anúncio visualizado /ou software instalado pelos Serviços e pela Plataforma e respectiva hora que foram acessados.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "5. COOKIES",
                          style: textTitleTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "  5.1 Periodicamente o MOMENTO FISCAL ou seus provedores e parceiros de serviços autorizados, podem utilizar \"cookies\" ou outros recursos para permitir que terceiros coletem ou compartilhem informações relativamente ao uso dos Serviços ou da Plataforma por você. São justamente essas funcionalidades que nos ajudarão a melhorar nossa Plataforma e os Serviços que oferecemos, nos ajudarão a oferecer novos serviços e recursos e/ou nos permitirá, bem como nossos parceiros de publicidade e propaganda a oferecer conteúdo mais relevante para você, inclusive através de remarket. \"Cookies\" são identificadores que armazenamos no seu computador ou dispositivo móvel e gravam dados sobre o seu computador ou dispositivo, como e quando os Serviços ou Plataforma são usados ou visitados, por quantas pessoas e outras atividades em nossa Plataforma. Podemos vincular informações de cookies a dados pessoais. Os cookies também vinculam informação sobre os itens que você selecionou para compra e as páginas da internet que visualizou. Essa informação é usada para acompanhar seu carrinho de compras e para fornecer conteúdo específico do seu interesse, para permitir que nossos parceiros de publicidade e propaganda a oferecerem propaganda em sites na internet, e monitorar e conduzir análise quanto ao uso dos Serviços.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  5.2 Você pode recusar o uso de cookies selecionando as configurações apropriadas no seu navegador ou dispositivo. No entanto, observe que, se você fizer isso, poderá não conseguir usar todas as funcionalidades da nossa Plataforma ou dos Serviços.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "6. COMO USAMOS AS INFORMAÇÕES QUE VOCÊ NOS FORNECE?",
                          style: textTitleTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "  6.1 Podemos coletar, usar, divulgar e / ou processar seus dados pessoais para uma ou mais das seguintes finalidades:",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Considerar e/ou processar sua aplicação / transação conosco ou suas transações ou comunicações com terceiros por meio dos Serviços;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Gerenciar, operar, fornecer e / ou administrar seu uso e/ou acesso a nossos Serviços e nossa Plataforma (incluindo, sem limitação, lembrar suas preferências), bem como seu relacionamento e conta de usuário conosco;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Responder, processar, lidar ou concluir uma transação e/ou atender às suas solicitações de determinados produtos e serviços e notificá-lo sobre problemas de serviço e ações incomuns da conta;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Impor nossos Termos de Serviço ou quaisquer contratos de licença de usuário final aplicáveis;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Proteger a segurança pessoal e os direitos, propriedade ou segurança de terceiros;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Para identificação, verificação, auditorias, processos de “conheça seu cliente, prevenção e combate à fraude e lavagem de dinheiro;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Para análise e tomada de decisões relacionadas ao seu perfil de risco de crédito e verificação da elegibilidade para produtos de crédito a ser realizada por terceiros que eventualmente poderão ofertar produtos de crédito a você;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Manter e administrar quaisquer atualizações de software e/ou outras atualizações e suporte que possam ser necessários periodicamente para garantir o bom funcionamento de nossos Serviços;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Para lidar com ou facilitar o atendimento ao cliente, executar suas instruções, lidar ou responder a quaisquer perguntas feitas por (ou que se supõem que sejam dadas por) você ou em seu nome;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Entrar em contato com você ou comunicar com você por chamada de voz, mensagem de texto e/ou fax, e-mail e/ou correio postal ou de outra forma com o objetivo de administrar e/ou gerenciar seu relacionamento conosco ou o uso de nossos Serviços, tais como, mas não limitados a lhe comunicar informações administrativas relacionadas aos nossos Serviços. Você reconhece e concorda que tal comunicação por nós pode ser por meio de correspondência, documentos ou avisos para você, o que pode envolver a divulgação de certos dados pessoais sobre você para fornecer a entrega dos mesmos, bem como na capa externa da envelopes / encomendas de correio;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Para permitir que outros usuários interajam, se conectem com você ou veja algumas das suas atividades na Plataforma, inclusive para informá-lo quando outro Usuário lhe enviar uma mensagem privada ou postar um comentário para você na Plataforma ou relacionado ao uso de funcionalidades de interação social na Plataforma;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Conduzir atividades de pesquisa, análise e desenvolvimento (incluindo, entre outras, análises de dados, pesquisas, desenvolvimento de produtos e serviços e/ou criação de perfis), analisar como você usa nossos Serviços, para recomendar produtos e/ou serviços do seu interesse, aprimorar nossos Serviços ou produtos e/ou aprimorar sua experiência de cliente;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Permitir auditorias e pesquisas para, entre outras coisas, validar o tamanho e a composição do nosso público-alvo e entender sua experiência com os Serviços do MOMENTO FISCAL.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Para marketing e publicidade, nesse sentido, enviar a você por vários canais e modos de comunicação de marketing, informações e materiais promocionais e relacionados a produtos e/ou serviços (incluindo, sem limitação, produtos e/ou serviços de terceiros com os quais o MOMENTO FISCAL pode colaborar ou se associar) que o MOMENTO FISCAL (e/ou suas afiliadas ou empresas relacionadas) possam estar vendendo, comercializando ou promovendo, se esses produtos ou serviços existem agora ou são criados no futuro. Você pode cancelar o recebimento das informações de marketing a qualquer momento, usando a função de cancelamento da inscrição no material de marketing eletrônico. Podemos usar suas informações de contato para enviar nossos boletins informativos ou material de publicitários de nossas empresas relacionadas;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Responder a processos legais ou cumprir conforme exigido por qualquer lei aplicável, requisitos governamentais ou regulamentares de qualquer jurisdição relevante ou quando o MARCO ZERO COMUNICAÇÃO E FILMAGENS, de boa-fé, acredita que a disponibilização de tais informações é necessária, incluindo, sem limitação, atender aos requisitos para fazer a divulgação sob os requisitos de qualquer lei vinculativa para o MOMENTO FISCAL ou seus representantes relacionados ou afiliados (incluindo, quando aplicável, a apresentação do seu nome, contatos e dados empresariais e da respectiva pessoa jurídica);",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Elaborar estatísticas e pesquisas para relatórios internos e estatutários e/ou requisitos de manutenção de registros;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Realizar a devida diligência ou outras atividades de triagem (incluindo, sem limitação, verificação de antecedentes) de acordo com as obrigações legais ou regulamentaresou com nossos procedimentos de gerenciamento de riscos que possam ser exigidos por lei ou que tenham sido implementados por nós;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Auditar nossos serviços ou os negócios do MOMENTO FISCAL.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Para prevenir ou investigar qualquer suspeita ou efetiva violação aos nossos Termos de Serviço, fraude, atividade ilegal, omissão ou má conduta, seja relacionada ao uso de nossos Serviços ou qualquer outro assunto decorrente de seu relacionamento conosco;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Para responder a qualquer ameaças e/ou reclamações realizadas contra o MOMENTO FISCAL ou outras demandas em que qualquer Conteúdo viole os direitos de terceiros;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Para armazenar, hospedar, fazer backup (seja para recuperação de desastres ou de outra forma) dos seus dados pessoais, dentro ou fora da sua jurisdição;",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Para lidar com e/ou facilitar uma transação de negócios ou uma potencial transação de negócios, onde essa transação envolva o Comprador como participante ou envolva apenas uma corporação ou afiliada relacionada ao Comprador como participante ou envolva o Comprador e/ou qualquer um ou mais Corporações ou afiliadas relacionadas ao Comprador como participante(s), e pode haver outras organizações de terceiros que participam dessa transação. Uma “transação de negócios” refere-se à compra, venda, locação, incorporação, fusão ou qualquer outra aquisição, alienação ou financiamento de uma organização ou parte de uma organização ou de qualquer negócio ou ativo de uma organização; e/ou",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  • Quaisquer outras finalidades das quais notificamos você no momento de obter o seu consentimento. (coletivamente, os “Objetivos”).",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "  6.2 Você reconhece, consente e concorda que o MOMENTO FISCAL pode acessar, preservar e divulgar as informações e o Conteúdo da sua conta, se exigido por lei ou por ordem judicial ou por qualquer autoridade governamental ou reguladora competente com jurisdição sobre o MOMENTO FISCAL ou de boa-fé acredite de que a preservação ou divulgação do acesso é razoavelmente necessária para: (a) cumprir o devido processo e/ou obrigações legais; (b) atender a uma solicitação de qualquer autoridade governamental ou regulatória competente com jurisdição sobre MOMENTO FISCAL (c) fazer cumprir os Termos de Serviço do MOMENTO FISCAL, esta Política de Privacidade e demais Políticas e Regulamentos do MARCO ZERO COMUNICAÇÃO E FILMAGENS; (d) responder a qualquer ameaça ou reclamação efetiva feita contra o MOMENTO FISCAL ou reclamação de que qualquer Conteúdo viola os direitos de terceiros; (e) responder às suas solicitações de atendimento ao cliente; ou (f) proteger os direitos, propriedade ou segurança pessoal do MOMENTO FISCAL, seus usuários e/ou o público.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  6.3 Como os objetivos para os quais coletaremos, usaremos, divulgaremos ou processaremos seus dados pessoais dependem das circunstâncias em questão, esse objetivo pode não aparecer acima. No entanto, notificaremos você sobre esse outro objetivo no momento de obter o seu consentimento, a menos que o processamento dos dados aplicáveis sem o seu consentimento seja permitido pelas Leis de Privacidade.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "7. COMO A MOMENTO FISCAL PROTEGE E RETÉM AS INFORMAÇÕES DO CLIENTE?",
                          style: textTitleTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "  7.1 Implementamos uma variedade de esforços e medidas de segurança para garantir a segurança de seus dados pessoais em nossos sistemas. Os dados pessoais do usuário estão contidos em redes protegidas e são acessíveis apenas por um número limitado de funcionários que têm direitos especiais de acesso a esses sistemas. Contudo, inevitavelmente não há como conceder garantias de segurança absoluta.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  7.2 Reteremos suas informações pessoais de acordo com as Leis de Privacidade e/ou outras leis aplicáveis. Ou seja, destruiremos ou tornaremos seus dados pessoais anônimos quando tivermos determinado razoavelmente que (i) a finalidade para a qual esses dados pessoais foram coletados não está mais sendo atendida pela retenção desses dados pessoais; (ii) a retenção não é mais necessária para fins legais ou comerciais; e (iii) nenhum outro interesse legítimo que justifique a retenção de tais dados pessoais. Se você parar de usar a Plataforma, ou se sua permissão para usá-la e/ou os Serviços forem encerrados ou retirados, podemos continuar armazenando, usando e/ou divulgando seus dados pessoais de acordo com esta Política de Privacidade e nossas obrigações sob as Leis de Privacidade. Sujeitos a legislação aplicável, podemos descartar com segurança seus dados pessoais sem aviso prévio.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "9. INFORMAÇÕES COLETADAS POR TERCEIROS",
                          style: textTitleTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  9.1 Nossa plataforma usa o Google Analytics, um serviço de analítica Web fornecido pelo Google, Inc. (\"Google\"). O Google Analytics usa cookies, que são arquivos de texto colocados  no seu dispositivo, para ajudar a Plataforma a analisar como os Usuários usam a Plataforma. As informações geradas pelos cookies sobre seu uso da Plataforma (incluindo seu endereço IP) serão transmitidas e armazenadas pelo Google em servidores nos Estados Unidos. O Google usará essas informações com o objetivo de avaliar o uso da Plataforma, produzir relatórios sobre a atividade do site para os operadores e fornecer outros serviços relacionados à atividade do site e ao uso da Internet. O Google também poderá transferir essas informações para terceiros, sempre que for exigido por lei ou no caso do Google delegar a terceiros o processamento dessas informações. O Google não associará o seu endereço IP a nenhum outro dado mantido pelo Google.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  9.2 Nós e os terceiros, podemos periodicamente disponibilizar downloads de aplicativos de software para seu uso através da Plataforma ou através dos Serviços. Esses aplicativos podem acessar separadamente e permitir que terceiros visualizem suas informações identificáveis,como seu nome, seu ID de usuário, o endereço IP do seu dispositivo ou outras informações, como cookies que você possa ter instalado anteriormente ou que foram instalados para você por um aplicativo ou site de software de terceiros. Além disso, esses aplicativos podem solicitar que você forneça informações adicionais diretamente a terceiros. Produtos ou serviços de terceiros fornecidos por meio desses aplicativos não pertencem ou são controlados pelo MOMENTO FISCAL. Você é incentivado a ler os termos e outras políticas publicadas por terceiros em seus sites ou de outra forma.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "10. ISENÇÃO DE RESPONSABILIDADE RELATIVA À SEGURANÇA E SITES DETERCEIROS",
                          style: textTitleTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "  10.1 NÃO GARANTIMOS A SEGURANÇA DE DADOS PESSOAIS E/OU OUTRAS INFORMAÇÕES QUE VOCÊ FORNECE EM SITES DE TERCEIROS. Implementamos uma variedade de medidas de segurança para manter a segurança dos seus dados pessoais queestão em nossa posse ou sob nosso controle. Seus dados pessoais estão contidos em redes protegidas e são acessíveis apenas por um número limitado de pessoas que têm direitos especiais de acesso a esses sistemas e são obrigados a manter os dados pessoais em sigilo. Quando você faz pedidos ou acessa seus dados pessoais, oferecemos o uso de um servidor seguro. Todos os dados pessoais ou informações confidenciais que você fornece são criptografados em nossos bancos de dados para serem acessados apenas conforme indicado acima.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  10.2 Na tentativa de fornecer maior valor a você, podemos escolher vários sites de terceiros para vincular e enquadrar dentro da Plataforma. Também podemos participar de uma marca conjunta e outros relacionamentos para oferecer comércio eletrônico e outros serviços e recursos aos nossos visitantes. Esses sites vinculados têm políticas de privacidade separadas e independentes, assim como acordos de segurança. Mesmo que o terceiro seja afiliado a nós, não temos controle sobre esses sites vinculados, cada um com práticas de privacidade e coleta de dados separadas, independentemente de nós. Os dados coletados por nossos parceiros de marca conjunta ou sites de terceiros (mesmo se oferecidos em ou através de nossa Plataforma) podem não ser recebidos por nós.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  10.3 Por isso não temos qualquer responsabilidade ou obrigação pelos conteúdos, acordos de segurança (ou falta dele) e atividades desses sites vinculados. Esses sites vinculados são apenas para sua conveniência e, portanto, você os acessa por seu próprio risco. No entanto, procuramos proteger a integridade de nossa Plataforma e os links colocados sobre cada um deles e, portanto, agradecemos qualquer feedback sobre esses sites vinculados (incluindo, sem limitação, se um link específico não funcionar).",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "11. O MOMENTO FISCAL TRANSFERIRÁ SUAS INFORMAÇÕES PARA O EXTERIOR?",
                          style: textTitleTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "  11.1 Seus dados pessoais e/ou informações podem ser transferidos, armazenados ou processados fora do seu país para uma ou mais finalidades. Em qualquer caso, o MOMENTO FISCAL apenas transferirá suas informações para o exterior de acordo com as Leis de Privacidade aplicáveis e para (i) países, jurisdições e/ou centros de dados que forneçam o nível adequado de proteção de dados pessoais ou; (ii) adotando as medidas cabíveis a fim de proporcionar a necessária proteção aos seus dados pessoais, que podem envolver o estabelecimento de acordos com cláusulas específicas destinadas a estabelecer os critérios e níveis de segurança adequados e exercício dos direitos dos titulares de dados nos termos da LGPD.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "12. COMO VOCÊ PODE RETIRAR O CONSENTIMENTO, SOLICITAR ACESSO OU CORRIGIR AS INFORMAÇÕES QUE VOCÊ FORNECEU?",
                          style: textTitleTermOfUse,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "  12.1 Retirada do Consentimento",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  12.1.1 Você pode retirar seu consentimento para a coleta, uso e/ou divulgação de seus dados pessoais em nossa posse ou sob nosso controle, bem como requerer que seus dados pessoais sejam deletados, enviando um e-mail para nosso Responsável pela Proteção de DadosPessoais em contato@fiscojurdf.com.br , e nós vamos processar a solicitação de acordo com a presente Política de Privacidade, bem como nossas obrigações disposta nas leis de privacidade e outras leis aplicáveis No entanto, a retirada do consentimento pode significar quenão poderemos continuar fornecendo os Serviços a você e que talvez precisemos encerrar seu relacionamento existente e/ou o contrato que você possui conosco.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  12.1.2 Quando Você compartilha Conteúdo do YouTube, além de retirar seu consentimento enviando-nos um e-mail de acordo com a Seção 14.1, você também pode revogar o acesso da MOMENTO FISCAL aos seus dados pessoais por meio da página de configurações de segurança do Google em https://security.google.com/settings/security/permissions.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  12.2 Solicitando Acesso a, ou Correção de Dados Pessoais",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  12.2.1 Se você tiver uma conta conosco, poderá acessar e/ou corrigir pessoalmente seus dados pessoais atualmente em nossa posse ou controle através da página de Configurações da Conta na Plataforma. Se você não tiver uma conta conosco, poderá solicitar acesso e/ou correção de seus dados pessoais atualmente em nossa posse ou controle, enviando uma solicitação por escrito para nós. Nós precisaremos de informações suficientes sobre você para verificar sua identidade e a natureza da sua solicitação, a fim de poder atender a sua solicitação. Portanto, envie sua solicitação por escrito enviando um e-mail ao nosso Responsável pela Proteção de Dados Pessoais em contato@fiscojurdf.com.br",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "  12.2.2 Reservamo-nos o direito de apenas executar as solicitações dos usuários com relação aseus dados pessoais de acordo com as disposições estabelecidas na legislação de privacidade e proteção de dados aplicável, incluindo os casos em que a legislação eventualmente permita que o controlador e/ou operador dos dados pessoais se recuse a atender solicitação dos titulares dos dados pessoais em determinadas circunstâncias e/ou mediante o cumprimento de requisitos específicos pelos titular dos dados.",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "13. PERGUNTAS, PREOCUPAÇÕES OU RECLAMAÇÕES? CONTATE-NOS",
                          style: textTermOfUse,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "13.1 Se você tiver alguma dúvida ou preocupação sobre nossas práticas de privacidade, entre em contato conosco pelo e-mail contato@fiscojurdf.com.br",
                          style: textTermOfUse,
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                  backgroundColor: colorTertiary,
                ),
                onPressed: onPressedIsTerm,
                child: const Text(
                  'Concordo',
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
          ),
        ],
      );
    },
  );
}

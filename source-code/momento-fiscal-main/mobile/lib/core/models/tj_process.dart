class TjProcess {
  late String? code;
  late String? url;
  late String? processType;
  late String? participationType;
  late String? interestedPartyName;
  late String? mainSubject;
  late String? receivedAt;
  late String? receivedLocation;

  late String? processCode;
  late String? processClass;
  late String? subject;
  late String? forum;
  late String? court;
  late String? judge;
  late String? distribution;
  late String? controlNumber;
  late String? area;
  late num? value;

  TjProcess({
    this.code,
    this.url,
    this.processType,
    this.participationType,
    this.interestedPartyName,
    this.mainSubject,
    this.receivedAt,
    this.receivedLocation,
    this.processCode,
    this.processClass,
    this.subject,
    this.forum,
    this.court,
    this.judge,
    this.distribution,
    this.controlNumber,
    this.area,
    this.value,
  });

  @override
  String toString() {
    return 'TjProcess(code: $code, url: $url, processType: $processType, participationType: $participationType, interestedPartyName: $interestedPartyName, mainSubject: $mainSubject, receivedAt: $receivedAt, receivedLocation: $receivedLocation, processCode: $processCode, processClass: $processClass, subject: $subject, forum: $forum, court: $court, judge: $judge, distribution: $distribution, controlNumber: $controlNumber, area: $area, value: $value)';
  }
}
